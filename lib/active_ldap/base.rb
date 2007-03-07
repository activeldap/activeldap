# === activeldap - an OO-interface to LDAP objects inspired by ActiveRecord
# Author: Will Drewry <will@alum.bu.edu>
# License: See LICENSE and COPYING.txt
# Copyright 2004-2006 Will Drewry <will@alum.bu.edu>
# Some portions Copyright 2006 Google Inc
#
# == Summary
# ActiveLdap lets you read and update LDAP entries in a completely object
# oriented fashion, even handling attributes with multiple names seamlessly.
# It was inspired by ActiveRecord so extending it to deal with custom
# LDAP schemas is as effortless as knowing the 'ou' of the objects, and the
# primary key. (fix this up some)
#
# == Example
#   irb> require 'active_ldap'
#   > true
#   irb> user = ActiveLdap::User.new("drewry")
#   > #<ActiveLdap::User:0x402e...
#   irb> user.cn
#   > "foo"
#   irb> user.common_name
#   > "foo"
#   irb> user.cn = "Will Drewry"
#   > "Will Drewry"
#   irb> user.cn
#   > "Will Drewry"
#   irb> user.save
#
#

require 'English'

module ActiveLdap
  # OO-interface to LDAP assuming pam/nss_ldap-style organization with
  # Active specifics
  # Each subclass does a ldapsearch for the matching entry.
  # If no exact match, raise an error.
  # If match, change all LDAP attributes in accessor attributes on the object.
  # -- these are ACTUALLY populated from schema - see active_ldap/schema.rb
  #    example
  # -- extract objectClasses from match and populate
  # Multiple entries become lists.
  # If this isn't read-only then lists become multiple entries, etc.

  class Error < StandardError
  end

  # ConfigurationError
  #
  # An exception raised when there is a problem with Base.connect arguments
  class ConfigurationError < Error
  end

  # DeleteError
  #
  # An exception raised when an ActiveLdap delete action fails
  class DeleteError < Error
  end

  # SaveError
  #
  # An exception raised when an ActiveLdap save action failes
  class SaveError < Error
  end

  # AuthenticationError
  #
  # An exception raised when user authentication fails
  class AuthenticationError < Error
  end

  # ConnectionError
  #
  # An exception raised when the LDAP conenction fails
  class ConnectionError < Error
  end

  # ObjectClassError
  #
  # An exception raised when an objectClass is not defined in the schema
  class ObjectClassError < Error
  end

  # AttributeAssignmentError
  #
  # An exception raised when there is an issue assigning a value to
  # an attribute
  class AttributeAssignmentError < Error
  end

  # TimeoutError
  #
  # An exception raised when a connection action fails due to a timeout
  class TimeoutError < Error
  end

  class EntryNotFound < Error
  end

  class EntryAlreadyExist < Error
  end

  class StrongAuthenticationRequired < Error
  end

  class DistinguishedNameInvalid < Error
    attr_reader :dn, :reason
    def initialize(dn, reason=nil)
      @dn = dn
      @reason = reason
      message = "#{@dn} is invalid distinguished name (dn)"
      message << ": #{@reason}"if @reason
      super(message)
    end
  end

  class DistinguishedNameNotSetError < Error
  end

  class EntryNotSaved < Error
  end

  class RequiredObjectClassMissed < Error
  end

  class RequiredAttributeMissed < Error
  end

  class EntryInvalid < Error
  end

  class UnwillingToPerform < Error
  end

  class ConnectionNotEstablished < Error
  end

  class AdapterNotSpecified < Error
  end

  class UnknownAttribute < Error
    attr_reader :name
    def initialize(name)
      @name = name
      super("#{@name} is unknown attribute")
    end
  end

  # Base
  #
  # Base is the primary class which contains all of the core
  # ActiveLdap functionality. It is meant to only ever be subclassed
  # by extension classes.
  class Base
    if Reloadable.const_defined?(:Deprecated)
      include Reloadable::Deprecated
    else
      include Reloadable::Subclasses
    end

    VALID_LDAP_MAPPING_OPTIONS = [:dn_attribute, :prefix, :classes, :scope]

    cattr_accessor :logger
    cattr_accessor :configurations
    @@configurations = {}

    def self.class_local_attr_accessor(search_ancestors, *syms)
      syms.flatten.each do |sym|
        class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          def self.#{sym}(search_superclasses=#{search_ancestors})
            @#{sym} ||= nil
            return @#{sym} if @#{sym}
            if search_superclasses
              target = superclass
              value = nil
              loop do
                break nil unless target.respond_to?("#{sym}")
                value = target.#{sym}
                break if value
                target = target.superclass
              end
              value
            else
              nil
            end
          end
          def #{sym}; self.class.#{sym}; end
          def self.#{sym}=(value); @#{sym} = value; end
          def #{sym}=(value); self.class.#{sym} = value; end
        EOS
      end
    end

    class_local_attr_accessor false, :prefix, :base, :dn_attribute
    class_local_attr_accessor true, :ldap_scope, :required_classes

    class << self
      # Hide new in Base
      private :new
      private :dn_attribute

      # Connect and bind to LDAP creating a class variable for use by
      # all ActiveLdap objects.
      #
      # == +config+
      # +config+ must be a hash that may contain any of the following fields:
      # :password_block, :logger, :host, :port, :base, :bind_dn,
      # :try_sasl, :allow_anonymous
      # :bind_dn specifies the DN to bind with.
      # :password_block specifies a Proc object that will yield a String to
      #   be used as the password when called.
      # :logger specifies a preconfigured Log4r::Logger to be used for all
      #   logging
      # :host sets the LDAP server hostname
      # :port sets the LDAP server port
      # :base overwrites Base.base - this affects EVERYTHING
      # :try_sasl indicates that a SASL bind should be attempted when binding
      #   to the server (default: false)
      # :sasl_mechanisms is an array of SASL mechanism to try
      #   (default: ["GSSAPI", "CRAM-MD5", "EXTERNAL"])
      # :allow_anonymous indicates that a true anonymous bind is allowed when
      #   trying to bind to the server (default: true)
      # :retries - indicates the number of attempts to reconnect that will be
      #   undertaken when a stale connection occurs. -1 means infinite.
      # :sasl_quiet - if true, sets @sasl_quiet on the Ruby/LDAP connection
      # :method - whether to use :ssl, :tls, or :plain (unencrypted)
      # :retry_wait - seconds to wait before retrying a connection
      # :ldap_scope - dictates how to find objects. ONELEVEL by default to
      #   avoid dn_attr collisions across OUs. Think before changing.
      # :timeout - time in seconds - defaults to disabled. This CAN interrupt
      #   search() requests. Be warned.
      # :retry_on_timeout - whether to reconnect when timeouts occur. Defaults
      #   to true
      # See lib/configuration.rb for defaults for each option
      def establish_connection(config=nil)
        super
        ensure_logger
        connection.connect
        # Make irb users happy with a 'true'
        true
      end

      def create(attributes=nil, &block)
        if attributes.is_a?(Array)
          attributes.collect {|attrs| create(attrs, &block)}
        else
          object = new(attributes, &block)
          object.save
          object
        end
      end

      def search(options={}, &block)
        attr = options[:attribute]
        value = options[:value] || '*'
        filter = options[:filter]
        prefix = options[:prefix]
        classes = options[:classes]

        value = value.first if value.is_a?(Array) and value.first.size == 1
        if filter.nil? and !value.is_a?(String)
          raise ArgumentError, "Search value must be a String"
        end

        _attr, value, _prefix = split_search_value(value)
        attr ||= _attr || dn_attribute || "objectClass"
        prefix ||= _prefix
        if filter.nil?
          filter = "(#{attr}=#{escape_filter_value(value, true)})"
          filter = "(&#{filter}#{object_class_filters(classes)})"
        end
        _base = [prefix, base].compact.reject{|x| x.empty?}.join(",")
        search_options = {
          :base => _base,
          :scope => options[:scope] || ldap_scope,
          :filter => filter,
          :limit => options[:limit],
          :attributes => options[:attributes]
        }
        connection.search(search_options) do |dn, attrs|
          attributes = {}
          attrs.each do |key, value|
            normalized_attr, normalized_value = make_subtypes(key, value)
            attributes[normalized_attr] ||= []
            attributes[normalized_attr].concat(normalized_value)
          end
          value = [dn, attributes]
          value = yield(value) if block_given?
          value
        end
      end

      # This class function is used to setup all mappings between the subclass
      # and ldap for use in activeldap
      #
      # Example:
      #   ldap_mapping :dn_attribute => 'uid', :prefix => 'ou=People',
      #                :classes => ['top', 'posixAccount'],
      #                :scope => :sub
      def ldap_mapping(options={})
        validate_ldap_mapping_options(options)
        dn_attribute = options[:dn_attribute] || default_dn_attribute
        prefix = options[:prefix] || default_prefix
        classes = options[:classes]
        scope = options[:scope]

        self.dn_attribute = dn_attribute
        self.prefix = prefix
        self.ldap_scope = scope
        self.required_classes = classes

        public_class_method :new
        public_class_method :dn_attribute
      end

      alias_method :base_inheritable, :base
      # Base.base
      #
      # This method when included into Base provides
      # an inheritable, overwritable configuration setting
      #
      # This should be a string with the base of the
      # ldap server such as 'dc=example,dc=com', and
      # it should be overwritten by including
      # configuration.rb into this class.
      # When subclassing, the specified prefix will be concatenated.
      def base
        _base = base_inheritable
        _base = configuration[:base] if _base.nil? and configuration
        _base ||= base_inheritable(true)
        [prefix, _base].find_all do |component|
          component and !component.empty?
        end.join(",")
      end

      alias_method :ldap_scope_without_validation=, :ldap_scope=
      def ldap_scope=(scope)
        scope = scope.to_sym if scope.is_a?(String)
        if scope.nil? or scope.is_a?(Symbol)
          self.ldap_scope_without_validation = scope
        else
          raise ConfigurationError,
                  ":ldap_scope '#{scope.inspect}' must be a Symbol"
        end
      end

      def dump(options={})
        ldifs = []
        options = {:base => base, :scope => ldap_scope}.merge(options)
        connection.search(options) do |dn, attributes|
          ldifs << to_ldif(dn, attributes)
        end
        ldifs.join("\n")
      end

      def to_ldif(dn, attributes)
        connection.to_ldif(dn, unnormalize_attributes(attributes))
      end

      def load(ldifs)
        connection.load(ldifs)
      end

      def destroy(targets, options={})
        targets = [targets] unless targets.is_a?(Array)
        targets.each do |target|
          find(target, options).destroy
        end
      end

      def destroy_all(filter=nil, options={})
        targets = []
        if filter.is_a?(Hash)
          options = options.merge(filter)
          filter = nil
        end
        options = options.merge(:filter => filter) if filter
        find(:all, options).sort_by do |target|
          target.dn.reverse
        end.reverse.each do |target|
          target.destroy
        end
      end

      def delete(targets, options={})
        targets = [targets] unless targets.is_a?(Array)
        targets = targets.collect do |target|
          ensure_dn_attribute(ensure_base(target))
        end
        connection.delete(targets, options)
      end

      def delete_all(filter=nil, options={})
        options = {:base => base, :scope => ldap_scope}.merge(options)
        options = options.merge(:filter => filter) if filter
        targets = connection.search(options).collect do |dn, attributes|
          dn
        end.sort_by do |dn|
          dn.reverse
        end.reverse

        connection.delete(targets)
      end

      def add(dn, entries, options={})
        unnormalized_entries = entries.collect do |type, key, value|
          [type, key, unnormalize_attribute(key, value)]
        end
        connection.add(dn, unnormalized_entries, options)
      end

      def modify(dn, entries, options={})
        unnormalized_entries = entries.collect do |type, key, value|
          [type, key, unnormalize_attribute(key, value)]
        end
        connection.modify(dn, unnormalized_entries, options)
      end

      # find
      #
      # Finds the first match for value where |value| is the value of some 
      # |field|, or the wildcard match. This is only useful for derived classes.
      # usage: Subclass.find(:attribute => "cn", :value => "some*val")
      #        Subclass.find('some*val')
      def find(*args)
        options = extract_options_from_args!(args)
        args = [:first] if args.empty? and !options.empty?
        case args.first
        when :first
          find_initial(options)
        when :all
          find_every(options)
        else
          find_from_dns(args, options)
        end
      end

      def exists?(dn, options={})
        prefix = /^#{Regexp.escape(truncate_base(ensure_dn_attribute(dn)))}/ #
        dn_suffix = nil
        not search({:value => dn}.merge(options)).find do |_dn,|
          if prefix.match(_dn)
            begin
              dn_suffix ||= DN.parse(base)
              DN.parse(_dn) - dn_suffix
              true
            rescue DistinguishedNameInvalid, ArgumentError
              false
            end
          else
            false
          end
        end.nil?
      end

      def update(dn, attributes, options={})
        if dn.is_a?(Array)
          i = -1
          dns = dn
          dns.collect do |dn|
            i += 1
            update(dn, attributes[i], options)
          end
        else
          object = find(dn, options)
          object.update_attributes(attributes)
          object
        end
      end

      def update_all(attributes, filter=nil, options={})
        search_options = options
        if filter
          if /[=\(\)&\|]/ =~ filter
            search_options = search_options.merge(:filter => filter)
          else
            search_options = search_options.merge(:value => filter)
          end
        end
        targets = search(search_options).collect do |dn, attrs|
          dn
        end

        entries = attributes.collect do |name, value|
          normalized_name, normalized_value = normalize_attribute(name, value)
          [:replace, normalized_name,
           unnormalize_attribute(normalized_name, normalized_value)]
        end
        targets.each do |dn|
          connection.modify(dn, entries, options)
        end
      end

      def base_class
        if self == Base or superclass == Base
          self
        else
          superclass.base_class
        end
      end

      def human_attribute_name(attribute_key_name)
        attribute_key_name.humanize
      end

      private
      def validate_ldap_mapping_options(options)
        options.assert_valid_keys(VALID_LDAP_MAPPING_OPTIONS)
      end

      def extract_options_from_args!(args)
        args.last.is_a?(Hash) ? args.pop : {}
      end

      def object_class_filters(classes=nil)
        (classes || required_classes).collect do |name|
          "(objectClass=#{escape_filter_value(name, true)})"
        end.join("")
      end

      def find_initial(options)
        find_every(options.merge(:limit => 1)).first
      end

      def find_every(options)
        search(options).collect do |dn, attrs|
          instantiate([dn, attrs])
        end
      end

      def find_from_dns(dns, options)
        expects_array = dns.first.is_a?(Array)
        return [] if expects_array and dns.first.empty?

        dns = dns.flatten.compact.uniq

        case dns.size
        when 0
          raise EntryNotFound, "Couldn't find #{name} without a DN"
        when 1
          result = find_one(dns.first, options)
          expects_array ? [result] : result
        else
          find_some(dns, options)
        end
      end

      def find_one(dn, options)
        attr, value, prefix = split_search_value(dn)
        filters = [
          "(#{attr || dn_attribute}=#{escape_filter_value(value, true)})",
          object_class_filters(options[:classes]),
          options[:filter],
        ]
        filter = "(&#{filters.compact.join('')})"
        options = {:prefix => prefix}.merge(options.merge(:filter => filter))
        result = find_initial(options)
        if result
          result
        else
          message = "Couldn't find #{name} with DN=#{dn}"
          message << " #{options[:filter]}" if options[:filter]
          raise EntryNotFound, message
        end
      end

      def find_some(dns, options)
        dn_filters = dns.collect do |dn|
          attr, value, prefix = split_search_value(dn)
          attr ||= dn_attribute
          filter = "(#{attr}=#{escape_filter_value(value, true)})"
          if prefix
            filter = "(&#{filter}(dn=*,#{escape_filter_value(prefix)},#{base}))"
          end
          filter
        end
        filters = [
          "(|#{dn_filters.join('')})",
          object_class_filters(options[:classes]),
          options[:filter],
        ]
        filter = "(&#{filters.compact.join('')})"
        result = find_every(options.merge(:filter => filter))
        if result.size == dns.size
          result
        else
          message = "Couldn't find all #{name} with DNs (#{dns.join(', ')})"
          message << " #{options[:filter]}"if options[:filter]
          raise EntryNotFound, message
        end
      end

      def split_search_value(value)
        attr = prefix = nil
        begin
          dn = DN.parse(value)
          attr, value = dn.rdns.first.to_a.first
          rest = dn.rdns[1..-1]
          prefix = DN.new(*rest).to_s unless rest.empty?
        rescue DistinguishedNameInvalid
          begin
            dn = DN.parse("DUMMY=#{value}")
            _, value = dn.rdns.first.to_a.first
            rest = dn.rdns[1..-1]
            prefix = DN.new(*rest).to_s unless rest.empty?
          rescue DistinguishedNameInvalid
          end
        end

        prefix = nil if prefix == base
        prefix = truncate_base(prefix) if prefix
        [attr, value, prefix]
      end

      def escape_filter_value(value, without_asterisk=false)
        value.gsub(/[\*\(\)\\\0]/) do |x|
          if without_asterisk and x == "*"
            x
          else
            "\\%02x" % x[0]
          end
        end
      end

      def ensure_dn(target)
        attr, value, prefix = split_search_value(target)
        "#{attr || dn_attribute}=#{value},#{prefix || base}"
      end

      def ensure_dn_attribute(target)
        "#{dn_attribute}=" +
          target.gsub(/^\s*#{Regexp.escape(dn_attribute)}\s*=\s*/i, '')
      end

      def ensure_base(target)
        [truncate_base(target),  base].join(',')
      end

      def truncate_base(target)
        if /,/ =~ target
          begin
            (DN.parse(target) - DN.parse(base)).to_s
          rescue DistinguishedNameInvalid, ArgumentError
            target
          end
        else
          target
        end
      end

      def ensure_logger
        @@logger ||= configuration[:logger]
        # Setup default logger to console
        if @@logger.nil?
          require 'log4r'
          @@logger = Log4r::Logger.new('activeldap')
          @@logger.level = Log4r::OFF
          Log4r::StderrOutputter.new 'console'
          @@logger.add('console')
        end
        configuration[:logger] ||= @@logger
      end

      def instantiate(entry)
        dn, attributes = entry
        if self.class == Class
          klass = self.ancestors[0].to_s.split(':').last
          real_klass = self.ancestors[0]
        else
          klass = self.class.to_s.split(':').last
          real_klass = self.class
        end

        obj = real_klass.allocate
        obj.instance_eval do
          initialize_by_ldap_data(dn, attributes)
        end
        obj
      end

      def default_dn_attribute
        if name.empty?
          "cn"
        else
          Inflector.underscore(Inflector.demodulize(name))
        end
      end

      def default_prefix
        if name.empty?
          nil
        else
          "ou=#{Inflector.pluralize(Inflector.demodulize(name))}"
        end
      end
    end

    self.ldap_scope = :sub
    self.required_classes = ['top']

    include Enumerable

    ### All instance methods, etc

    # new
    #
    # Creates a new instance of Base initializing all class and all
    # initialization.  Defines local defaults. See examples If multiple values
    # exist for dn_attribute, the first one put here will be authoritative
    def initialize(attributes=nil)
      init_base
      @new_entry = true
      if attributes.nil?
        apply_object_class(required_classes)
      elsif attributes.is_a?(String) or attributes.is_a?(Array)
        apply_object_class(required_classes)
        self.dn = attributes
      elsif attributes.is_a?(Hash)
        classes, attributes = extract_object_class(attributes)
        apply_object_class(classes | required_classes)
        normalized_attributes = {}
        attributes.each do |key, value|
          real_key = to_real_attribute_name(key)
          normalized_attributes[real_key] = value if real_key
        end
        self.dn = normalized_attributes[dn_attribute]
        self.attributes = normalized_attributes
      else
        message = "'#{attributes.inspect}' must be either "
        message << "nil, DN value as String or Array or attributes as Hash"
        raise ArgumentError, message
      end
      yield self if block_given?
    end

    # Returns true if the +comparison_object+ is the same object, or is of
    # the same type and has the same dn.
    def ==(comparison_object)
      comparison_object.equal?(self) or
        (comparison_object.instance_of?(self.class) and
         comparison_object.dn == dn and
         !comparison_object.new_entry?)
    end

    # Delegates to ==
    def eql?(comparison_object)
      self == (comparison_object)
    end

    # Delegates to id in order to allow two records of the same type and id
    # to work with something like:
    #   [ User.find("a"), User.find("b"), User.find("c") ] &
    #     [ User.find("a"), User.find("d") ] # => [ User.find("a") ]
    def hash
      dn.hash
    end

    def may
      ensure_apply_object_class
      @may
    end

    def must
      ensure_apply_object_class
      @must
    end

    # attributes
    #
    # Return attribute methods so that a program can determine available
    # attributes dynamically without schema awareness
    def attribute_names
      logger.debug {"stub: attribute_names called"}
      ensure_apply_object_class
      return @attr_methods.keys
    end

    def attribute_present?(name)
      values = get_attribute(name, true)
      !values.empty? or values.any? {|x| not (x and x.empty?)}
    end

    # exists?
    #
    # Return whether the entry exists in LDAP or not
    def exists?
      self.class.exists?(dn)
    end

    # new_entry?
    #
    # Return whether the entry is new entry in LDAP or not
    def new_entry?
      @new_entry
    end

    # dn
    #
    # Return the authoritative dn
    def dn
      logger.debug {"stub: dn called"}
      dn_value = id
      if dn_value.nil?
        raise DistinguishedNameNotSetError.new,
                "#{dn_attribute} value of #{self} doesn't set"
      end
      _base = base
      _base = nil if _base.empty?
      ["#{dn_attribute}=#{dn_value}", _base].compact.join(",")
    end

    def id
      get_attribute(dn_attribute)
    end

    def dn=(value)
      set_attribute(dn_attribute, value)
    end
    alias_method(:id=, :dn=)

    # destroy
    #
    # Delete this entry from LDAP
    def destroy
      logger.debug {"stub: delete called"}
      begin
        self.class.delete(dn)
        @new_entry = true
      rescue Error
        raise DeleteError.new("Failed to delete LDAP entry: '#{dn}'")
      end
    end

    # save
    #
    # Save and validate this object into LDAP
    # either adding or replacing attributes
    # TODO: Relative DN support
    def save
      create_or_update
    end

    def save!
      unless create_or_update
        raise EntryNotSaved, "entry #{dn} can't saved"
      end
    end

    # method_missing
    #
    # If a given method matches an attribute or an attribute alias
    # then call the appropriate method.
    # TODO: Determine if it would be better to define each allowed method
    #       using class_eval instead of using method_missing.  This would
    #       give tab completion in irb.
    def method_missing(name, *args, &block)
      logger.debug {"stub: called method_missing" +
                      "(#{name.inspect}, #{args.inspect})"}
      ensure_apply_object_class

      key = name.to_s
      case key
      when /=$/
        real_key = $PREMATCH
        logger.debug {"method_missing: have_attribute? #{real_key}"}
        if have_attribute?(real_key, ['objectClass'])
          if args.size != 1
            raise ArgumentError,
                    "wrong number of arguments (#{args.size} for 1)"
          end
          logger.debug {"method_missing: calling set_attribute" +
                          "(#{real_key}, #{args.inspect})"}
          return set_attribute(real_key, *args, &block)
        end
      when /(?:(_before_type_cast)|(\?))?$/
        real_key = $PREMATCH
        before_type_cast = !$1.nil?
        query = !$2.nil?
        logger.debug {"method_missing: have_attribute? #{real_key}"}
        if have_attribute?(real_key, ['objectClass'])
          if args.size > 1
            raise ArgumentError,
              "wrong number of arguments (#{args.size} for 1)"
          end
          if before_type_cast
            return get_attribute_before_type_cast(real_key, *args)
          elsif query
            return get_attribute_as_query(real_key, *args)
          else
            return get_attribute(real_key, *args)
          end
        end
      end
      super
    end

    # Add available attributes to the methods
    def methods(inherited_too=true)
      ensure_apply_object_class
      target_names = @attr_methods.keys + @attr_aliases.keys - ['objectClass']
      super + target_names.uniq.collect do |x|
        [x, "#{x}=", "#{x}?", "#{x}_before_type_cast"]
      end.flatten
    end

    alias_method :respond_to_without_attributes?, :respond_to?
    def respond_to?(name, include_priv=false)
      have_attribute?(name.to_s) or
        (/(?:=|\?|_before_type_cast)$/ =~ name.to_s and
         have_attribute?($PREMATCH)) or
        super
    end

    # Updates a given attribute and saves immediately
    def update_attribute(name, value)
      set_attribute(name, value) if have_attribute?(name)
      save
    end

    # This performs a bulk update of attributes and immediately
    # calls #save.
    def update_attributes(attrs)
      self.attributes = attrs
      save
    end

    # This returns the key value pairs in @data with all values
    # cloned
    def attributes
      Marshal.load(Marshal.dump(@data))
    end

    # This allows a bulk update to the attributes of a record
    # without forcing an immediate save or validation.
    #
    # It is unwise to attempt objectClass updates this way.
    # Also be sure to only pass in key-value pairs of your choosing.
    # Do not let URL/form hackers supply the keys.
    def attributes=(hash_or_assoc)
      targets = remove_attributes_protected_from_mass_assignment(hash_or_assoc)
      targets.each do |key, value|
        set_attribute(key, value) if have_attribute?(key)
      end
    end

    def to_ldif
      self.class.to_ldif(dn, normalize_data(@data))
    end

    def to_xml(options={})
      root = options[:root] || Inflector.underscore(self.class.name)
      result = "<#{root}>\n"
      result << "  <dn>#{dn}</dn>\n"
      normalize_data(@data).sort_by {|key, values| key}.each do |key, values|
        targets = []
        values.each do |value|
          if value.is_a?(Hash)
            value.each do |option, real_value|
              targets << [real_value, " #{option}=\"true\""]
            end
          else
            targets << [value]
          end
        end
        targets.sort_by {|value, attr| value}.each do |value, attr|
          result << "  <#{key}#{attr}>#{value}</#{key}>\n"
        end
      end
      result << "</#{root}>\n"
      result
    end

    def have_attribute?(name, except=[])
      real_name = to_real_attribute_name(name)
      real_name and !except.include?(real_name)
    end
    alias_method :has_attribute?, :have_attribute?

    def reload
      _, attributes = self.class.search(:value => id).find do |_dn, _attributes|
        dn == _dn
      end
      raise EntryNotFound, "Can't find dn '#{dn}' to reload" if attributes.nil?

      @ldap_data.update(attributes)
      classes, attributes = extract_object_class(attributes)
      apply_object_class(classes)
      self.attributes = attributes
      @new_entry = false
      self
    end

    def [](name, force_array=false)
      if name == "dn"
        array_of(dn, force_array)
      else
        get_attribute(name, force_array)
      end
    end

    def []=(name, value)
      set_attribute(name, value)
    end

    def each
      @data.each do |key, values|
        yield(key.dup, values.dup)
      end
    end

    private
    def logger
      @@logger
    end

    def extract_object_class(attributes)
      classes = []
      attrs = attributes.reject do |key, value|
        if key.to_s == 'objectClass' or
            Inflector.underscore(key) == 'object_class'
          classes |= [value].flatten
          true
        else
          false
        end
      end
      [classes, attrs]
    end

    def init_base
      check_configuration
      init_instance_variables
    end

    def initialize_by_ldap_data(dn, attributes)
      init_base
      @new_entry = false
      @ldap_data = attributes
      classes, attributes = extract_object_class(attributes)
      apply_object_class(classes)
      self.dn = dn
      self.attributes = attributes
      yield self if block_given?
    end

    def to_real_attribute_name(name, allow_normalized_name=false)
      ensure_apply_object_class
      name = name.to_s
      real_name = @attr_methods[name]
      real_name ||= @attr_aliases[Inflector.underscore(name)]
      if real_name
        real_name
      elsif allow_normalized_name
        @attr_methods[@normalized_attr_names[normalize_attribute_name(name)]]
      else
        nil
      end
    end

    def ensure_apply_object_class
      current_object_class = @data['objectClass']
      return if current_object_class.nil? or current_object_class == @last_oc
      apply_object_class(current_object_class)
    end

    # enforce_type
    #
    # enforce_type applies your changes without attempting to write to LDAP.
    # This means that if you set userCertificate to somebinary value, it will
    # wrap it up correctly.
    def enforce_type(key, value)
      logger.debug {"stub: enforce_type called"}
      ensure_apply_object_class
      # Enforce attribute value formatting
      result = self.class.normalize_attribute(key, value)[1]
      logger.debug {"stub: enforce_types done"}
      result
    end

    def init_instance_variables
      @data = {} # where the r/w entry data is stored
      @ldap_data = {} # original ldap entry data
      @attr_methods = {} # list of valid method calls for attributes used for
                         # dereferencing
      @normalized_attr_names = {} # list of normalized attribute name
      @attr_aliases = {} # aliases of @attr_methods
      @last_oc = false # for use in other methods for "caching"
      @base = nil
    end

    # apply_object_class
    #
    # objectClass= special case for updating appropriately
    # This updates the objectClass entry in @data. It also
    # updating all required and allowed attributes while
    # removing defined attributes that are no longer valid
    # given the new objectclasses.
    def apply_object_class(val)
      logger.debug {"stub: objectClass=(#{val.inspect}) called"}
      new_oc = val
      new_oc = [val] if new_oc.class != Array
      new_oc = new_oc.uniq
      return new_oc if @last_oc == new_oc

      # Store for caching purposes
      @last_oc = new_oc.dup

      # Set the actual objectClass data
      define_attribute_methods('objectClass')
      replace_class(*new_oc)

      # Build |data| from schema
      # clear attr_method mapping first
      @attr_methods = {}
      @normalized_attr_names = {}
      @attr_aliases = {}
      @musts = {}
      @mays = {}
      new_oc.each do |objc|
        # get all attributes for the class
        attributes = schema.class_attributes(objc)
        @musts[objc] = attributes[:must]
        @mays[objc] = attributes[:may]
      end
      @must = normalize_attribute_names(@musts.values)
      @may = normalize_attribute_names(@mays.values)
      (@must + @may).uniq.each do |attr|
        # Update attr_method with appropriate
        define_attribute_methods(attr)
      end
    end

    def normalize_attribute_names(names)
      names.flatten.uniq.collect do |may|
        schema.attribute_aliases(may).first
      end
    end

    alias_method :base_of_class, :base
    def base
      logger.debug {"stub: called base"}
      [@base, base_of_class].compact.join(",")
    end

    undef_method :base=
    def base=(object_local_base)
      @base = object_local_base
    end

    # get_attribute
    #
    # Return the value of the attribute called by method_missing?
    def get_attribute(name, force_array=false)
      logger.debug {"stub: called get_attribute" +
                      "(#{name.inspect}, #{force_array.inspect}"}
      get_attribute_before_type_cast(name, force_array)
    end

    def get_attribute_as_query(name, force_array=false)
      logger.debug {"stub: called get_attribute_as_query" +
                      "(#{name.inspect}, #{force_array.inspect}"}
      value = get_attribute_before_type_cast(name, force_array)
      if force_array
        value.collect {|x| !false_value?(x)}
      else
        !false_value?(value)
      end
    end

    def false_value?(value)
      value.nil? or value == false or value == [] or
        value == "false" or value == "FALSE" or value == ""
    end

    def get_attribute_before_type_cast(name, force_array=false)
      logger.debug {"stub: called get_attribute_before_type_cast" +
                      "(#{name.inspect}, #{force_array.inspect}"}
      attr = to_real_attribute_name(name)

      value = @data[attr] || []
      # Return a copy of the stored data
      if force_array
        value.dup
      else
        array_of(value.dup, false)
      end
    end

    # set_attribute
    #
    # Set the value of the attribute called by method_missing?
    def set_attribute(name, value)
      logger.debug {"stub: called set_attribute" +
                      "(#{name.inspect}, #{value.inspect})"}

      # Get the attr and clean up the input
      attr = to_real_attribute_name(name)
      raise UnknownAttribute.new(name) if attr.nil?

      if attr == dn_attribute and value.is_a?(String)
        value, @base = split_dn_value(value)
      end

      logger.debug {"set_attribute(#{name.inspect}, #{value.inspect}): " +
                      "method maps to #{attr}"}

      # Enforce LDAP-pleasing values
      logger.debug {"value = #{value.inspect}, value.class = #{value.class}"}
      real_value = value
      # Squash empty values
      if value.class == Array
        real_value = value.collect {|c| (c.nil? or c.empty?) ? [] : c}.flatten
      end
      real_value = [] if real_value.nil?
      real_value = [] if real_value == ''
      real_value = [real_value] if real_value.class == String
      real_value = [real_value.to_s] if real_value.class == Fixnum
      # NOTE: Hashes are allowed for subtyping.

      # Assign the value
      @data[attr] = enforce_type(attr, real_value)

      # Return the passed in value
      logger.debug {"stub: exiting set_attribute"}
      @data[attr]
    end

    def split_dn_value(value)
      dn_value = nil
      begin
        dn_value = DN.parse(value)
      rescue DistinguishedNameInvalid
        dn_value = DN.parse("#{dn_attribute}=#{value}")
      end
      begin
        dn_value -= DN.parse(base_of_class)
      rescue ArgumentError
      end
      val, *bases = dn_value.rdns
      [val.values[0], bases.empty? ? nil : DN.new(*bases).to_s]
    end

    # define_attribute_methods
    #
    # Make a method entry for _every_ alias of a valid attribute and map it
    # onto the first attribute passed in.
    def define_attribute_methods(attr)
      logger.debug {"stub: called define_attribute_methods(#{attr.inspect})"}
      return if @attr_methods.has_key? attr
      schema.attribute_aliases(attr).each do |ali|
        logger.debug {"associating #{ali} --> #{attr}"}
        @attr_methods[ali] = attr
        logger.debug {"associating #{Inflector.underscore(ali)}" +
                        " --> #{attr}"}
        @attr_aliases[Inflector.underscore(ali)] = attr
        logger.debug {"associating #{normalize_attribute_name(ali)}" +
                        " --> #{attr}"}
        @normalized_attr_names[normalize_attribute_name(ali)] = attr
      end
      logger.debug {"stub: leaving define_attribute_methods(#{attr.inspect})"}
    end

    # array_of
    #
    # Returns the array form of a value, or not an array if
    # false is passed in.
    def array_of(value, to_a=true)
      logger.debug {"stub: called array_of" +
                      "(#{value.inspect}, #{to_a.inspect})"}
      case value
      when Array
        if to_a or value.size > 1
          value.collect {|v| array_of(v, to_a)}
        else
          if value.empty?
            nil
          else
            array_of(value.first, to_a)
          end
        end
      when Hash
        if to_a
          [value]
        else
          result = {}
          value.each {|k, v| result[k] = array_of(v, to_a)}
          result
        end
      else
        to_a ? [value.to_s] : value.to_s
      end
    end

    def normalize_data(data, except=[])
      result = {}
      data.each do |key, values|
        next if except.include?(key)
        real_name = to_real_attribute_name(key)
        next if real_name and except.include?(real_name)
        real_name ||= key
        result[real_name] ||= []
        result[real_name].concat(values)
      end
      result
    end

    def collect_modified_entries(ldap_data, data)
      entries = []
      # Now that all the subtypes will be treated as unique attributes
      # we can see what's changed and add anything that is brand-spankin'
      # new.
      logger.debug {'#collect_modified_entries: traversing ldap_data ' +
                      'determining replaces and deletes'}
      ldap_data.each do |k, v|
        value = data[k] || []

        next if v == value

        # Create mod entries
        if value.empty?
          # Since some types do not have equality matching rules,
          # delete doesn't work
          # Replacing with nothing is equivalent.
          logger.debug {"#save: removing attribute from existing entry: #{k}"}
          if !data.has_key?(k) and schema.binary_required?(k)
            value = [{'binary' => []}]
          end
        else
          # Ditched delete then replace because attribs with no equality
          # match rules will fails
          logger.debug {"#collect_modified_entries: updating attribute of" +
                          " existing entry: #{k}: #{value.inspect}"}
        end
        entries.push([:replace, k, value])
      end
      logger.debug {'#collect_modified_entries: finished traversing' +
                      ' ldap_data'}
      logger.debug {'#collect_modified_entries: traversing data ' +
                      'determining adds'}
      data.each do |k, v|
        value = v || []
        next if ldap_data.has_key?(k) or value.empty?

        # Detect subtypes and account for them
        logger.debug {"#save: adding attribute to existing entry: " +
                        "#{k}: #{value.inspect}"}
        # REPLACE will function like ADD, but doesn't hit EQUALITY problems
        # TODO: Added equality(attr) to Schema
        entries.push([:replace, k, value])
      end

      entries
    end

    def collect_all_entries(data)
      dn_attr = to_real_attribute_name(dn_attribute)
      dn_value = data[dn_attr]
      logger.debug {'#collect_all_entries: adding all attribute value pairs'}
      logger.debug {"#collect_all_entries: adding " +
                      "#{dn_attr.inspect} = #{dn_value.inspect}"}

      entries = []
      entries.push([:add, dn_attr, dn_value])

      oc_value = data['objectClass']
      logger.debug {"#collect_all_entries: adding objectClass = " +
                      "#{oc_value.inspect}"}
      entries.push([:add, 'objectClass', oc_value])
      data.each do |key, value|
        next if value.empty? or key == 'objectClass' or key == dn_attr

        logger.debug {"#collect_all_entries: adding attribute to new " +
                        "entry: #{key.inspect}: #{value.inspect}"}
        entries.push([:add, key, value])
      end

      entries
    end

    def check_configuration
      unless dn_attribute
        raise ConfigurationError,
                "dn_attribute not set for this class: #{self.class}"
      end
    end

    def create_or_update
      new_entry? ? create : update
    end

    def prepare_data_for_saving
      logger.debug {"stub: save called"}

      # Expand subtypes to real ldap_data entries
      # We can't reuse @ldap_data because an exception would leave
      # an object in an unknown state
      logger.debug {"#save: expanding subtypes in @ldap_data"}
      ldap_data = normalize_data(@ldap_data)
      logger.debug {'#save: subtypes expanded for @ldap_data'}

      # Expand subtypes to real data entries, but leave @data alone
      logger.debug {'#save: expanding subtypes for @data'}
      bad_attrs = @data.keys - attribute_names
      data = normalize_data(@data, bad_attrs)
      logger.debug {'#save: subtypes expanded for @data'}

      success = yield(data, ldap_data)

      if success
        logger.debug {"#save: resetting @ldap_data to a dup of @data"}
        @ldap_data = Marshal.load(Marshal.dump(data))
        # Delete items disallowed by objectclasses.
        # They should have been removed from ldap.
        logger.debug {'#save: removing attributes from @ldap_data not ' +
                      'sent in data'}
        bad_attrs.each do |remove_me|
          @ldap_data.delete(remove_me)
        end
        logger.debug {'#save: @ldap_data reset complete'}
      end

      logger.debug {'stub: save exited'}
      success
    end

    def create
      prepare_data_for_saving do |data, ldap_data|
        entries = collect_all_entries(data)
        logger.debug {"#create: adding #{dn}"}
        begin
          self.class.add(dn, entries)
          logger.debug {"#create: add successful"}
          @new_entry = false
        rescue UnwillingToPerform
          logger.warn {"#create: didn't perform: #{$!.message}"}
        end
        true
      end
    end

    def update
      prepare_data_for_saving do |data, ldap_data|
        entries = collect_modified_entries(ldap_data, data)
        logger.debug {'#update: traversing data complete'}
        logger.debug {"#update: modifying #{dn}"}
        self.class.modify(dn, entries)
        logger.debug {'#update: modify successful'}
        true
      end
    end
  end # Base
end # ActiveLdap
