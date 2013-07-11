require 'digest/md5'

require 'active_ldap/adapter/base'

module ActiveLdap
  module Adapter
    class Base
      class << self
        def net_ldap_connection(options)
          require 'active_ldap/adapter/net_ldap_ext'
          NetLdap.new(options)
        end
      end
    end

    class NetLdap < Base
      METHOD = {
        :ssl => :simple_tls,
        :tls => :start_tls,
        :plain => nil,
      }

      def connect(options={})
        super do |host, port, method|
          config = {
            :host => host,
            :port => port,
          }
          config[:encryption] = {:method => method} if method
          begin
            uri = construct_uri(host, port, method == :simple_tls)
            with_start_tls = method == :start_tls
            info = {:uri => uri, :with_start_tls => with_start_tls}
            [log("connect", info) {Net::LDAP::Connection.new(config)},
             uri, with_start_tls]
          rescue Net::LDAP::LdapError
            raise ConnectionError, $!.message
          end
        end
      end

      def unbind(options={})
        super do
          log("unbind") do
            @connection.close # Net::LDAP doesn't implement unbind.
          end
        end
      end

      def bind(options={})
        begin
          super
        rescue Net::LDAP::LdapError
          raise AuthenticationError, $!.message
        end
      end

      def bind_as_anonymous(options={})
        super do
          execute(:bind, {:name => "bind: anonymous"}, {:method => :anonymous})
          true
        end
      end

      def search(options={})
        super(options) do |base, scope, filter, attrs, limit|
          args = {
            :base => base,
            :scope => scope,
            :filter => filter,
            :attributes => attrs,
            :size => limit,
          }
          info = {
            :base => base, :scope => scope_name(scope),
            :filter => filter, :attributes => attrs, :limit => limit
          }
          execute(:search, info, args) do |entry|
            attributes = {}
            entry.original_attribute_names.each do |name|
              value = entry[name]
              attributes[name] = value if value
            end
            yield([entry.dn, attributes])
          end
        end
      end

      def delete(targets, options={})
        super do |target|
          args = {:dn => target}
          info = args.dup
          execute(:delete, info, args)
        end
      end

      def add(dn, entries, options={})
        super do |_dn, _entries|
          attributes = {}
          _entries.each do |type, key, attrs|
            attrs.each do |name, values|
              attributes[name] = values
            end
          end
          args = {:dn => _dn, :attributes => attributes}
          info = args.dup
          execute(:add, info, args)
        end
      end

      def modify(dn, entries, options={})
        super do |_dn, _entries|
          info = {:dn => _dn, :attributes => _entries}
          execute(:modify, info,
                  :dn => _dn,
                  :operations => parse_entries(_entries))
        end
      end

      def modify_rdn(dn, new_rdn, delete_old_rdn, new_superior, options={})
        super do |_dn, _new_rdn, _delete_old_rdn, _new_superior|
          if _new_superior
            raise NotImplemented.new(_("modify RDN with new superior"))
          end
          info = {
            :name => "modify: RDN",
            :dn => _dn,
            :new_rdn => _new_rdn,
            :new_superior => _new_superior,
            :delete_old_rdn => _delete_old_rdn
          }
          execute(:rename, info,
                  :olddn => _dn,
                  :newrdn => _new_rdn,
                  :delete_attributes => _delete_old_rdn)
        end
      end

      private
      def execute(method, info=nil, *args, &block)
        name = (info || {}).delete(:name) || method
        result = log(name, info) do
          begin
            @connection.send(method, *args, &block)
          rescue Errno::EPIPE, Errno::ECONNRESET
            raise ConnectionError, "#{$!.class}: #{$!.message}"
          end
        end
        message = nil
        if result.is_a?(Hash)
          message = result[:errorMessage]
          result = result[:resultCode]
        end
        unless result.zero?
          klass = LdapError::ERRORS[result]
          klass ||= LdapError
          return if klass == LdapError::SizeLimitExceeded
          message = [Net::LDAP.result2string(result), message].compact.join(": ")
          raise klass, message
        end
      end

      def ensure_method(method)
        method ||= "plain"
        normalized_method = method.to_s.downcase.to_sym
        return METHOD[normalized_method] if METHOD.has_key?(normalized_method)

        available_methods = METHOD.keys.collect {|m| m.inspect}.join(", ")
        format = _("%s is not one of the available connect methods: %s")
        raise ConfigurationError, format % [method.inspect, available_methods]
      end

      def ensure_scope(scope)
        scope_map = {
          :base => Net::LDAP::SearchScope_BaseObject,
          :sub => Net::LDAP::SearchScope_WholeSubtree,
          :one => Net::LDAP::SearchScope_SingleLevel,
        }
        value = scope_map[scope || :sub]
        if value.nil?
          available_scopes = scope_map.keys.inspect
          format = _("%s is not one of the available LDAP scope: %s")
          raise ArgumentError, format % [scope.inspect, available_scopes]
        end
        value
      end

      def scope_name(scope)
        {
          Net::LDAP::SearchScope_BaseObject => :base,
          Net::LDAP::SearchScope_WholeSubtree => :sub,
          Net::LDAP::SearchScope_SingleLevel => :one,
        }[scope]
      end

      def sasl_bind(bind_dn, options={})
        super do |_bind_dn, mechanism, quiet|
          normalized_mechanism = mechanism.downcase.gsub(/-/, '_')
          sasl_bind_setup = "sasl_bind_setup_#{normalized_mechanism}"
          next unless respond_to?(sasl_bind_setup, true)
          initial_credential, challenge_response =
            send(sasl_bind_setup, _bind_dn, options)
          args = {
            :method => :sasl,
            :initial_credential => initial_credential,
            :mechanism => mechanism,
            :challenge_response => challenge_response,
          }
          info = {
            :name => "bind: SASL", :dn => _bind_dn, :mechanism => mechanism,
          }
          execute(:bind, info, args)
          true
        end
      end

      def sasl_bind_setup_digest_md5(bind_dn, options)
        initial_credential = ""
        nonce_count = 1
        challenge_response = Proc.new do |cred|
          params = parse_sasl_digest_md5_credential(cred)
          qops = params["qop"].split(/,/)
          unless qops.include?("auth")
            raise ActiveLdap::AuthenticationError,
                  _("unsupported qops: %s") % qops.inspect
          end
          qop = "auth"
          server = @connection.instance_variable_get("@conn").addr[2]
          realm = params['realm']
          uri = "ldap/#{server}"
          nc = "%08x" % nonce_count
          nonce = params["nonce"]
          cnonce = generate_client_nonce
          requests = {
            :username => bind_dn.inspect,
            :realm => realm.inspect,
            :nonce => nonce.inspect,
            :cnonce => cnonce.inspect,
            :nc => nc,
            :qop => qop,
            :maxbuf => "65536",
            "digest-uri" => uri.inspect,
          }
          a1 = "#{bind_dn}:#{realm}:#{password(cred, options)}"
          a1 = "#{Digest::MD5.digest(a1)}:#{nonce}:#{cnonce}"
          ha1 = Digest::MD5.hexdigest(a1)
          a2 = "AUTHENTICATE:#{uri}"
          ha2 = Digest::MD5.hexdigest(a2)
          response = "#{ha1}:#{nonce}:#{nc}:#{cnonce}:#{qop}:#{ha2}"
          requests["response"] = Digest::MD5.hexdigest(response)
          nonce_count += 1
          requests.collect do |key, value|
            "#{key}=#{value}"
          end.join(",")
        end
        [initial_credential, challenge_response]
      end

      def parse_sasl_digest_md5_credential(cred)
        params = {}
        cred.scan(/(\w+)=(\"?)(.+?)\2(?:,|$)/) do |name, sep, value|
          params[name] = value
        end
        params
      end

      CHARS = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
      def generate_client_nonce(size=32)
        nonce = ""
        size.times do |i|
          nonce << CHARS[rand(CHARS.size)]
        end
        nonce
      end

      def simple_bind(bind_dn, options={})
        super do |_bind_dn, password|
          args = {
            :method => :simple,
            :username => _bind_dn,
            :password => password,
          }
          execute(:bind, {:dn => _bind_dn}, args)
          true
        end
      end

      def parse_entries(entries)
        result = []
        entries.each do |type, key, attributes|
          mod_type = ensure_mod_type(type)
          attributes.each do |name, values|
            result << [mod_type, name, values]
          end
        end
        result
      end

      def ensure_mod_type(type)
        case type
        when :replace, :add, :delete
          type
        else
          raise ArgumentError, _("unknown type: %s") % type
        end
      end
    end
  end
end
