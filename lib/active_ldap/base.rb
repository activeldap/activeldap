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
require 'thread'

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
    include GetTextSupport
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
      if @reason
        message = _("%s is invalid distinguished name (DN): %s") % [@dn, @reason]
      else
        message = _("%s is invalid distinguished name (DN)") % @dn
      end
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

  class OperationNotPermitted < Error
  end

  class ConnectionNotEstablished < Error
  end

  class AdapterNotSpecified < Error
  end

  class AdapterNotFound < Error
    attr_reader :adapter
    def initialize(adapter)
      @adapter = adapter
      super(_("LDAP configuration specifies nonexistent %s adapter") % adapter)
    end
  end

  class UnknownAttribute < Error
    attr_reader :name
    def initialize(name)
      @name = name
      super(_("%s is unknown attribute") % @name)
    end
  end

  # Base
  #
  # Base is the primary class which contains all of the core
  # ActiveLdap functionality. It is meant to only ever be subclassed
  # by extension classes.
  class Base
    include GetTextSupport
    public :gettext

    if Object.const_defined?(:Reloadable)
      if Reloadable.const_defined?(:Deprecated)
        include Reloadable::Deprecated
      else
        include Reloadable::Subclasses
      end
    end

    VALID_LDAP_MAPPING_OPTIONS = [:dn_attribute, :prefix, :scope,
                                  :classes, :recommended_classes,
                                  :sort_by, :order]

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
                break nil unless target.respond_to?(:#{sym})
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

    class_local_attr_accessor false, :prefix, :base
    class_local_attr_accessor true, :dn_attribute, :scope, :sort_by, :order
    class_local_attr_accessor true, :required_classes, :recommended_classes

    class << self
      # Hide new in Base
      private :new

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
      # :logger specifies a logger object (Logger, Log4r::Logger and s on)
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
      # :scope - dictates how to find objects. ONELEVEL by default to
      #   avoid dn_attr collisions across OUs. Think before changing.
      # :timeout - time in seconds - defaults to disabled. This CAN interrupt
      #   search() requests. Be warned.
      # :retry_on_timeout - whether to reconnect when timeouts occur. Defaults
      #   to true
      # See lib/configuration.rb for defaults for each option
      def establish_connection(config=nil)
        super
        ensure_logger
        nil
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

      # This class function is used to setup all mappings between the subclass
      # and ldap for use in activeldap
      #
      # Example:
      #   ldap_mapping :dn_attribute => 'uid', :prefix => 'ou=People',
      #                :classes => ['top', 'posixAccount'],
      #                :scope => :sub
      def ldap_mapping(options={})
        options = options.symbolize_keys
        validate_ldap_mapping_options(options)

        self.dn_attribute = options[:dn_attribute] || default_dn_attribute
        self.prefix = options[:prefix] || default_prefix
        self.scope = options[:scope]
        self.required_classes = options[:classes]
        self.recommended_classes = options[:recommended_classes]
        self.sort_by = options[:sort_by]
        self.order = options[:order]

        public_class_method :new
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
          !component.blank?
        end.join(",")
      end

      alias_method :scope_without_validation=, :scope=
      def scope=(scope)
        validate_scope(scope)
        self.scope_without_validation = scope
      end

      def validate_scope(scope)
        scope = scope.to_sym if scope.is_a?(String)
        return if scope.nil? or scope.is_a?(Symbol)
        raise ConfigurationError,
                _("scope '%s' must be a Symbol") % scope.inspect
      end

      def base_class
        if self == Base or superclass == Base
          self
        else
          superclass.base_class
        end
      end

      def default_search_attribute
        dn_attribute
      end

      private
      def validate_ldap_mapping_options(options)
        options.assert_valid_keys(VALID_LDAP_MAPPING_OPTIONS)
      end

      def ensure_logger
        @@logger ||= configuration[:logger]
        # Setup default logger to console
        if @@logger.nil?
          require 'logger'
          @@logger = Logger.new(STDERR)
          @@logger.progname = 'ActiveLdap'
          @@logger.level = Logger::UNKNOWN
        end
        configuration[:logger] ||= @@logger
      end

      def instantiate(args)
        dn, attributes, options = args
        options ||= {}
        if self.class == Class
          klass = self.ancestors[0].to_s.split(':').last
          real_klass = self.ancestors[0]
        else
          klass = self.class.to_s.split(':').last
          real_klass = self.class
        end

        obj = real_klass.allocate
        conn = options[:connection] || connection
        obj.connection = conn if conn != connection
        obj.instance_eval do
          initialize_by_ldap_data(dn, attributes)
        end
        obj
      end

      def default_dn_attribute
        if name.empty?
          dn_attribute = nil
          parent_class = ancestors[1]
          if parent_class.respond_to?(:dn_attribute)
            dn_attribute = parent_class.dn_attribute
          end
          dn_attribute || "cn"
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

    self.scope = :sub
    self.required_classes = ['top']
    self.recommended_classes = []

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
      initial_classes = required_classes | recommended_classes
      if attributes.nil?
        apply_object_class(initial_classes)
      elsif attributes.is_a?(String) or attributes.is_a?(Array)
        apply_object_class(initial_classes)
        self.dn = attributes
      elsif attributes.is_a?(Hash)
        classes, attributes = extract_object_class(attributes)
        apply_object_class(classes | initial_classes)
        normalized_attributes = {}
        attributes.each do |key, value|
          real_key = to_real_attribute_name(key) || key
          normalized_attributes[real_key] = value
        end
        self.dn = normalized_attributes[dn_attribute]
        self.attributes = normalized_attributes
      else
        message = _("'%s' must be either nil, DN value as String or Array " \
                    "or attributes as Hash") % attributes.inspect
        raise ArgumentError, message
      end
      yield self if block_given?
      assert_dn_attribute
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
    def attribute_names(normalize=false)
      ensure_apply_object_class
      names = @attribute_names.keys
      if normalize
        names.collect do |name|
          to_real_attribute_name(name)
        end.uniq
      else
        names
      end
    end

    def attribute_present?(name)
      values = get_attribute(name, true)
      !values.empty? or values.any? {|x| not (x and x.empty?)}
    end

    # exist?
    #
    # Return whether the entry exists in LDAP or not
    def exist?
      self.class.exists?(dn)
    end
    alias_method(:exists?, :exist?)

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
      return base if @dn_is_base

      dn_value = id
      if dn_value.nil?
        raise DistinguishedNameNotSetError.new,
                _("%s's DN attribute (%s) isn't set") % [self, dn_attribute]
      end
      _base = base
      _base = nil if _base.empty?
      ["#{dn_attribute}=#{dn_value}", _base].compact.join(",")
    end

    def id
      get_attribute(dn_attribute)
    end

    def to_param
      id
    end

    def dn=(value)
      set_attribute(dn_attribute, value)
    end
    alias_method(:id=, :dn=)

    alias_method(:dn_attribute_of_class, :dn_attribute)
    def dn_attribute
      @dn_attribute || dn_attribute_of_class
    end

    def default_search_attribute
      self.class.default_search_attribute
    end

    # destroy
    #
    # Delete this entry from LDAP
    def destroy
      begin
        self.class.delete(dn)
        @new_entry = true
      rescue Error
        raise DeleteError.new(_("Failed to delete LDAP entry: %s") % dn)
      end
    end

    def delete(options={})
      super(dn, options)
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
        raise EntryNotSaved, _("entry %s can't be saved") % dn
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
      ensure_apply_object_class

      key = name.to_s
      case key
      when /=$/
        real_key = $PREMATCH
        if have_attribute?(real_key, ['objectClass'])
          if args.size != 1
            raise ArgumentError,
                    _("wrong number of arguments (%d for 1)") % args.size
          end
          return set_attribute(real_key, *args, &block)
        end
      when /(?:(_before_type_cast)|(\?))?$/
        real_key = $PREMATCH
        before_type_cast = !$1.nil?
        query = !$2.nil?
        if have_attribute?(real_key, ['objectClass'])
          if args.size > 1
            raise ArgumentError,
              _("wrong number of arguments (%d for 1)") % args.size
          end
          if before_type_cast
            return get_attribute_before_type_cast(real_key, *args)[1]
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
      target_names = @attribute_names.keys + @attribute_aliases.keys
      target_names -= ['objectClass', Inflector.underscore('objectClass')]
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
      send("#{name}=", value)
      save
    end

    # This performs a bulk update of attributes and immediately
    # calls #save.
    def update_attributes(attrs)
      self.attributes = attrs
      save
    end

    def update_attributes!(attrs)
      self.attributes = attrs
      save!
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
    def attributes=(new_attributes)
      return if new_attributes.nil?
      _schema = nil
      targets = remove_attributes_protected_from_mass_assignment(new_attributes)
      targets.each do |key, value|
        setter = "#{key}="
        unless respond_to?(setter)
          _schema ||= schema
          attribute = _schema.attribute(key)
          next if attribute.id.nil?
          define_attribute_methods(attribute)
        end
        send(setter, value)
      end
    end

    def to_ldif
      super(dn, normalize_data(@data))
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
      clear_association_cache
      _, attributes = search(:value => id).find do |_dn, _attributes|
        dn == _dn
      end
      if attributes.nil?
        raise EntryNotFound, _("Can't find DN '%s' to reload") % dn
      end

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

    def bind(config_or_password={}, &block)
      if config_or_password.is_a?(String)
        config = {:password => config_or_password}
      elsif config_or_password.respond_to?(:call)
        config = {:password_block => config_or_password}
      else
        config = config_or_password
      end
      config = {:bind_dn => dn, :allow_anonymous => false}.merge(config)
      config[:password_block] ||= block if block_given?
      establish_connection(config)

      before_connection = @connection
      begin
        @connection = nil
        connection.connect
        @connection = connection
        @schema = nil
        clear_association_cache
      rescue ActiveLdap::Error
        remove_connection
        @connection = before_connection
        raise
      end
      true
    end

    def schema
      @schema ||= super
    end

    alias_method :base_of_class, :base
    def base
      [@base, base_of_class].compact.join(",")
    end

    undef_method :base=
    def base=(object_local_base)
      @base = object_local_base
    end

    alias_method :scope_of_class, :scope
    def scope
      @scope || scope_of_class
    end

    undef_method :scope=
    def scope=(scope)
      self.class.validate_scope(scope)
      @scope = scope
    end

    def inspect
      abbreviate_instance_variables do
        super
      end
    end

    def pretty_print(q)
      abbreviate_instance_variables do
        q.pp_object(self)
      end
    end

    private
    def abbreviate_instance_variables
      @abbreviating ||= nil
      connection, @connection = @connection, nil
      schema, @schema = @schema, nil
      attribute_schemata, @attribute_schemata = @attribute_schemata, nil
      must, may = @must, @may
      object_classes = @object_classes
      unless @abbreviating
        @abbreviating = true
        @must, @may = @must.collect(&:name), @may.collect(&:name)
        @object_classes = @object_classes.collect(&:name)
      end
      yield
    ensure
      @connection = connection
      @schema = schema
      @attribute_schemata = attribute_schemata
      @must = must
      @may = may
      @object_classes = object_classes
      @abbreviating = false
    end

    def extract_object_class(attributes)
      classes = []
      attrs = attributes.stringify_keys.reject do |key, value|
        if key == 'objectClass' or
            key.underscore == 'object_class' or
            key.downcase == 'objectclass'
          classes |= [value].flatten
          true
        else
          false
        end
      end
      [classes, attrs]
    end

    def init_base
      init_instance_variables
    end

    def initialize_by_ldap_data(dn, attributes)
      init_base
      @new_entry = false
      @dn_is_base = false
      @ldap_data = attributes
      classes, attributes = extract_object_class(attributes)
      apply_object_class(classes)
      self.dn = dn
      self.attributes = attributes
      yield self if block_given?
      assert_dn_attribute
    end

    def instantiate(args)
      dn, attributes, options = args
      options ||= {}

      obj = self.class.allocate
      obj.connection = options[:connection] || @connection
      obj.instance_eval do
        initialize_by_ldap_data(dn, attributes)
      end
      obj
    end

    def to_real_attribute_name(name, allow_normalized_name=false)
      return name if name.nil?
      ensure_apply_object_class
      name = name.to_s
      real_name = @attribute_names[name]
      real_name ||= @attribute_aliases[Inflector.underscore(name)]
      if real_name
        real_name
      elsif allow_normalized_name
        @normalized_attribute_names[normalize_attribute_name(name)]
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
      ensure_apply_object_class
      # Enforce attribute value formatting
      normalize_attribute(key, value)[1]
    end

    def init_instance_variables
      @mutex = Mutex.new
      @data = {} # where the r/w entry data is stored
      @ldap_data = {} # original ldap entry data
      @attribute_schemata = {}
      @attribute_names = {} # list of valid method calls for attributes used
                            # for dereferencing
      @normalized_attribute_names = {} # list of normalized attribute name
      @attribute_aliases = {} # aliases of @attribute_names
      @last_oc = false # for use in other methods for "caching"
      @dn_attribute = nil
      @base = nil
      @scope = nil
      @connection ||= nil
    end

    # apply_object_class
    #
    # objectClass= special case for updating appropriately
    # This updates the objectClass entry in @data. It also
    # updating all required and allowed attributes while
    # removing defined attributes that are no longer valid
    # given the new objectclasses.
    def apply_object_class(val)
      new_oc = val
      new_oc = [val] if new_oc.class != Array
      new_oc = new_oc.uniq
      return new_oc if @last_oc == new_oc

      # Store for caching purposes
      @last_oc = new_oc.dup

      # Set the actual objectClass data
      define_attribute_methods(schema.attribute('objectClass'))
      replace_class(*new_oc)

      # Build |data| from schema
      # clear attribute name mapping first
      @attribute_schemata = {}
      @attribute_names = {}
      @normalized_attribute_names = {}
      @attribute_aliases = {}
      @must = []
      @may = []
      @object_classes = []
      new_oc.each do |objc|
        # get all attributes for the class
        object_class = schema.object_class(objc)
        @object_classes << object_class
        @must.concat(object_class.must)
        @may.concat(object_class.may)
      end
      @must.uniq!
      @may.uniq!
      (@must + @may).each do |attr|
        # Update attr_method with appropriate
        define_attribute_methods(attr)
      end
    end

    # get_attribute
    #
    # Return the value of the attribute called by method_missing?
    def get_attribute(name, force_array=false)
      name, value = get_attribute_before_type_cast(name, force_array)
      attribute = schema.attribute(name)
      type_cast(attribute, value)
    end

    def type_cast(attribute, value)
      case value
      when Hash
        result = {}
        value.each do |option, val|
          result[option] = type_cast(attribute, val)
        end
        result
      when Array
        value.collect do |val|
          type_cast(attribute, val)
        end
      else
        attribute.type_cast(value)
      end
    end

    def get_attribute_before_type_cast(name, force_array=false)
      name = to_real_attribute_name(name)

      value = @data[name] || []
      if force_array
        [name, value.dup]
      else
        [name, array_of(value.dup, false)]
      end
    end

    def get_attribute_as_query(name, force_array=false)
      name, value = get_attribute_before_type_cast(name, force_array)
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

    # set_attribute
    #
    # Set the value of the attribute called by method_missing?
    def set_attribute(name, value)
      attr = to_real_attribute_name(name)
      attr, value = update_dn(attr, value) if attr == dn_attribute
      raise UnknownAttribute.new(name) if attr.nil?

      case value
      when nil, ""
        value = []
      when Array
        value = value.collect {|c| c.blank? ? [] : c}.flatten
      when String
        value = [value]
      when Numeric
        value = [value.to_s]
      end

      @data[attr] = enforce_type(attr, value)
    end

    def update_dn(attr, value)
      @dn_is_base = false
      return [attr, value] if value.blank?

      new_dn_attribute, new_value, base = split_dn_value(value)
      if new_dn_attribute.nil? and new_value.nil?
        @dn_is_base = true
        @base = nil
        attr, value = DN.parse(base).rdns[0].to_a[0]
        @dn_attribute = attr
      else
        new_dn_attribute = to_real_attribute_name(new_dn_attribute)
        if new_dn_attribute
          value = new_value
          @base = base
          if dn_attribute != new_dn_attribute
            @dn_attribute = attr = new_dn_attribute
          end
        end
      end
      [attr, value]
    end

    def split_dn_value(value)
      dn_value = relative_dn_value = nil
      begin
        dn_value = DN.parse(value)
      rescue DistinguishedNameInvalid
        dn_value = DN.parse("#{dn_attribute}=#{value}")
      end

      begin
        relative_dn_value = dn_value - DN.parse(base_of_class)
        if relative_dn_value.rdns.empty?
          val = []
          bases = dn_value.rdns
        else
          val, *bases = relative_dn_value.rdns
        end
      rescue ArgumentError
        val, *bases = dn_value.rdns
      end

      dn_attribute_name, dn_attribute_value = val.to_a[0]
      [dn_attribute_name, dn_attribute_value,
       bases.empty? ? nil : DN.new(*bases).to_s]
    end

    # define_attribute_methods
    #
    # Make a method entry for _every_ alias of a valid attribute and map it
    # onto the first attribute passed in.
    def define_attribute_methods(attribute)
      real_name = attribute.name
      return if @attribute_schemata.has_key?(real_name)
      @attribute_schemata[real_name] = attribute
      ([real_name] + attribute.aliases).each do |name|
        @attribute_names[name] = real_name
        @attribute_aliases[Inflector.underscore(name)] = real_name
        @normalized_attribute_names[normalize_attribute_name(name)] = real_name
      end
    end

    # array_of
    #
    # Returns the array form of a value, or not an array if
    # false is passed in.
    def array_of(value, to_a=true)
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
      _schema = schema
      result = {}
      data.each do |key, values|
        next if except.include?(key)
        real_name = to_real_attribute_name(key)
        next if real_name and except.include?(real_name)
        real_name ||= key
        next if _schema.attribute(real_name).id.nil?
        result[real_name] ||= []
        result[real_name].concat(values)
      end
      result
    end

    def collect_modified_attributes(ldap_data, data)
      attributes = []
      # Now that all the options will be treated as unique attributes
      # we can see what's changed and add anything that is brand-spankin'
      # new.
      ldap_data.each do |k, v|
        value = data[k] || []

        next if v == value

        # Create mod entries
        if value.empty?
          # Since some types do not have equality matching rules,
          # delete doesn't work
          # Replacing with nothing is equivalent.
          if !data.has_key?(k) and schema.attribute(k).binary_required?
            value = [{'binary' => []}]
          end
        else
          # Ditched delete then replace because attribs with no equality
          # match rules will fails
        end
        attributes.push([:replace, k, value])
      end
      data.each do |k, v|
        value = v || []
        next if ldap_data.has_key?(k) or value.empty?

        # Detect subtypes and account for them
        # REPLACE will function like ADD, but doesn't hit EQUALITY problems
        # TODO: Added equality(attr) to Schema
        attributes.push([:replace, k, value])
      end

      attributes
    end

    def collect_all_attributes(data)
      dn_attr = to_real_attribute_name(dn_attribute)
      dn_value = data[dn_attr]

      attributes = []
      attributes.push([:add, dn_attr, dn_value])

      oc_value = data['objectClass']
      attributes.push([:add, 'objectClass', oc_value])
      data.each do |key, value|
        next if value.empty? or key == 'objectClass' or key == dn_attr

        attributes.push([:add, key, value])
      end

      attributes
    end

    def assert_dn_attribute
      unless dn_attribute
        raise ConfigurationError,
                _("dn_attribute isn't set for this class: %s") % self.class
      end
    end

    def create_or_update
      new_entry? ? create : update
    end

    def prepare_data_for_saving
      # Expand subtypes to real ldap_data attributes
      # We can't reuse @ldap_data because an exception would leave
      # an object in an unknown state
      ldap_data = normalize_data(@ldap_data)

      # Expand subtypes to real data attributes, but leave @data alone
      bad_attrs = @data.keys - attribute_names
      data = normalize_data(@data, bad_attrs)

      success = yield(data, ldap_data)

      if success
        @ldap_data = Marshal.load(Marshal.dump(data))
        # Delete items disallowed by objectclasses.
        # They should have been removed from ldap.
        bad_attrs.each do |remove_me|
          @ldap_data.delete(remove_me)
        end
      end

      success
    end

    def create
      prepare_data_for_saving do |data, ldap_data|
        attributes = collect_all_attributes(data)
        add_entry(dn, attributes)
        @new_entry = false
        true
      end
    end

    def update
      prepare_data_for_saving do |data, ldap_data|
        attributes = collect_modified_attributes(ldap_data, data)
        modify_entry(dn, attributes)
        true
      end
    end
  end # Base
end # ActiveLdap
