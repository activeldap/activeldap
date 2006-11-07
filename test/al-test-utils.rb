require 'test/unit'
require 'test-unit-ext'

require 'yaml'
require 'socket'
require 'openssl'

require 'activeldap'

module AlTestUtils
  def self.included(base)
    base.class_eval do
      include Config
      include Connection
      include Populate
      include TemporaryEntry
    end
  end

  module Config
    def setup
      super
      @base_dir = File.expand_path(File.dirname(__FILE__))
      @top_dir = File.expand_path(File.join(@base_dir, ".."))
      @example_dir = File.join(@top_dir, "examples")
      @config = read_config
    end

    def teardown
      super
    end

    module_function
    def read_config
      config_file = File.join(File.dirname(__FILE__), "config.yaml")

      unless File.exist?(config_file)
        raise "config file for testing doesn't exist: #{config_file}"
      end
      YAML.load(File.read(config_file))
    end

    def connect_config
      config = {}
      %w(user bind_format password password_block logger host port
         base try_sasl allow_anonymous retries sasl_quiet method
         retry_wait ldap_scope return_objects timeout
         retry_on_timeout).each do |field|
        name = "connect_#{field}"
        value = nil
        if respond_to?(name)
          value = __send__(name)
        else
          value = connection_config[field]
        end
        config[field.to_sym] = value unless value.nil?
      end
      config
    end

    def connection_config
      @config["connection"] ||= {}
    end

    def connect_host
      connection_config["host"] || "localhost"
    end

    def connect_port
      connection_config["port"] || 389
    end

    def connect_base
      connection_config["base"] || "dc=localdomain"
    end
  end

  module Connection
    def setup
      super
      ActiveLDAP::Base.establish_connection(connect_config)
    end

    def teardown
      ActiveLDAP::Base.clear_active_connections!
      super
    end
  end

  module Populate
    def setup
      @dumped_data = nil
      super
      begin
        @dumped_data = ActiveLDAP::Base.dump(:scope => :sub)
      rescue ActiveLDAP::ConnectionError
      end
      ActiveLDAP::Base.delete_all(nil, :scope => :sub)
      populate
    end

    def teardown
      if @dumped_data
        ActiveLDAP::Base.establish_connection(connect_config)
        ActiveLDAP::Base.delete_all(nil, :scope => :sub)
        ActiveLDAP::Base.load(@dumped_data)
      end
      super
    end

    def populate
      populate_base
      populate_ou
      populate_user_class
      populate_group_class
      populate_associations
    end

    def populate_base
      unless ActiveLDAP::Base.search(:scope => :base).empty?
        return
      end

      suffixes = []
      ActiveLDAP::Base.base.split(/,/).reverse_each do |suffix|
        prefix = suffixes.join(",")
        suffixes.unshift(suffix)
        name, value = suffix.split(/=/, 2)
        next unless name == "dc"
        dc_class = Class.new(ActiveLDAP::Base)
        dc_class.ldap_mapping :dnattr => "dc",
                              :prefix => "",
                              :classes => ["top", "dcObject", "organization"]
        dc_class.instance_variable_set("@base", prefix)
        begin
          dc = dc_class.new(value)
          dc.o = dc.dc
          dc.save
        rescue ActiveLDAP::SaveError
        end
      end
    end

    def ou_class(prefix="")
      ou_class = Class.new(ActiveLDAP::Base)
      ou_class.ldap_mapping :dnattr => "ou",
                            :prefix => prefix,
                            :classes => ["top", "organizationalUnit"]
      ou_class
    end

    def populate_ou
      %w(Users Groups).each do |ou_name|
        ou_class.new(ou_name).save
      end
    end

    def populate_user_class
      @user_class = Class.new(ActiveLDAP::Base)
      @user_class.ldap_mapping :dn_attribute => "uid",
                               :prefix => "ou=Users",
                               :scope => :sub,
                               :classes => ["posixAccount", "person"]
    end

    def populate_group_class
      @group_class = Class.new(ActiveLDAP::Base)
      @group_class.ldap_mapping :prefix => "ou=Groups",
                                :scope => :sub,
                                :classes => ["posixGroup"]
    end

    def populate_associations
      @user_class.belongs_to :primary_group,
                             :foreign_key => "gidNumber",
                             :primary_key => "gidNumber"
      @group_class.has_many :members, :wrap => "memberUid"
      @group_class.has_many :primary_members,
                            :foreign_key => "gidNumber",
                            :primary_key => "gidNumber"
      @user_class.set_associated_class(:primary_group, @group_class)
      @group_class.set_associated_class(:members, @user_class)
      @group_class.set_associated_class(:primary_members, @user_class)
    end
  end

  module TemporaryEntry
    @@certificate = nil
    def setup
      super
      @user_index = 0
      @group_index = 0
    end

    def make_temporary_user(config={})
      @user_index += 1
      uid = config[:uid] || "temp-user#{@user_index}"
      ensure_delete_user(uid) do
        password = config[:password] || "password"
        uid_number = config[:uid_number] || default_uid
        gid_number = config[:gid_number] || default_gid
        home_directory = config[:home_directory] || "/nonexistent"
        _wrap_assertion do
          assert_raise(ActiveLDAP::EntryNotFound) do
            @user_class.find(uid)
          end
          user = @user_class.new(uid)
          assert(!user.exists?)
          user.cn = user.uid
          user.sn = user.uid
          user.uid_number = uid_number
          user.gid_number = gid_number
          user.home_directory = home_directory
          unless config[:simple]
            user.add_class('shadowAccount', 'inetOrgPerson',
                           'organizationalPerson')
            user.user_certificate = certificate
            user.jpeg_photo = jpeg_photo
          end
          user.save
          assert(user.exists?)
          yield(@user_class.find(user.uid), password)
        end
      end
    end

    def make_temporary_group(config={})
      @group_index += 1
      cn = config[:cn] || "temp-group#{@group_index}"
      ensure_delete_group(cn) do
        gid_number = config[:gid_number] || default_gid
        _wrap_assertion do
          assert_raise(ActiveLDAP::EntryNotFound) do
            @group_class.find(cn)
          end
          group = @group_class.new(cn)
          assert(!group.exists?)
          group.gid_number = gid_number
          group.save
          assert(group.exists?)
          yield(@group_class.find(group.cn))
        end
      end
    end

    def ensure_delete_user(uid)
      yield(uid)
    ensure
      begin
        @user_class.destroy(uid)
      rescue ActiveLDAP::EntryNotFound
      end
    end

    def ensure_delete_group(cn)
      yield(cn)
    ensure
      begin
        @group_class.destroy(cn)
      rescue ActiveLDAP::EntryNotFound
      end
    end

    def default_uid
      "10000#{@user_index}"
    end

    def default_gid
      "10000#{@group_index}"
    end

    def certificate_path
      File.join(@example_dir, 'example.der')
    end

    def certificate
      return @@certificate if @@certificate
      if File.exists?(certificate_path)
        @@certificate = File.read(certificate_path)
        return @@certificate
      end

      rsa = OpenSSL::PKey::RSA.new(512)
      comment = "Generated by Ruby/OpenSSL"

      cert = OpenSSL::X509::Certificate.new
      cert.version = 3
      cert.serial = 0
      subject = [["OU", "test"],
                 ["CN", Socket.gethostname]]
      name = OpenSSL::X509::Name.new(subject)
      cert.subject = name
      cert.issuer = name
      cert.not_before = Time.now
      cert.not_after = Time.now + (365*24*60*60)
      cert.public_key = rsa.public_key

      ef = OpenSSL::X509::ExtensionFactory.new(nil, cert)
      ef.issuer_certificate = cert
      cert.extensions = [
        ef.create_extension("basicConstraints","CA:FALSE"),
        ef.create_extension("keyUsage", "keyEncipherment"),
        ef.create_extension("subjectKeyIdentifier", "hash"),
        ef.create_extension("extendedKeyUsage", "serverAuth"),
        ef.create_extension("nsComment", comment),
      ]
      aki = ef.create_extension("authorityKeyIdentifier",
                                "keyid:always,issuer:always")
      cert.add_extension(aki)
      cert.sign(rsa, OpenSSL::Digest::SHA1.new)

      @@certificate = cert.to_der
      @@certificate
    end

    def jpeg_photo_path
      File.join(@example_dir, 'example.jpg')
    end

    def jpeg_photo
      File.read(jpeg_photo_path)
    end
  end
end
