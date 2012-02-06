# -*- coding: utf-8 -*-
# === activeldap - an OO-interface to LDAP objects inspired by ActiveRecord
# Author: Will Drewry <will@alum.bu.edu>
# License: See LICENSE and COPYING
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
require 'erb'

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

  class << self
    include GetTextSupport
    def const_missing(id)
      case id
      when :ConnectionNotEstablished
        message =
          _("ActiveLdap::ConnectionNotEstablished has been deprecated " \
            "since 1.1.0. " \
            "Please use ActiveLdap::ConnectionNotSetup instead.")
        ActiveSupport::Deprecation.warn(message)
        const_set("ConnectionNotEstablished", ConnectionNotSetup)
        ConnectionNotEstablished
      else
        super
      end
    end
  end

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

  class DistinguishedNameInputInvalid < Error
    attr_reader :input
    def initialize(input=nil)
      @input = input
      super(_("invalid distinguished name (DN) to parse: %s") % @input.inspect)
    end
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

  class LdifInvalid < Error
    attr_reader :ldif, :reason, :line, :column, :nearest
    def initialize(ldif, reason=nil, line=nil, column=nil)
      @ldif = ldif
      @reason = reason
      @line = line
      @column = column
      @nearest = nil
      if @reason
        message = _("invalid LDIF: %s:") % @reason
      else
        message = _("invalid LDIF:")
      end
      if @line and @column
        @nearest = detect_nearest(@line, @column)
        snippet = generate_snippet
        message << "\n#{snippet}\n"
      end
      super("#{message}\n#{numbered_ldif}")
    end

    NEAREST_MARK = "|@|"
    private
    def detect_nearest(line, column)
      lines = Compatible.string_to_lines(@ldif).to_a
      nearest = lines[line - 1] || ""
      if column - 1 == nearest.size # for JRuby 1.0.2 :<
        nearest << NEAREST_MARK
      else
        nearest[column - 1, 0] = NEAREST_MARK
      end
      if nearest == NEAREST_MARK
        nearest = "#{lines[line - 2]}#{nearest}"
      end
      nearest
    end

    def generate_snippet
      nearest = @nearest.chomp
      column_column = ":#{@column}"
      target_position_info = "#{@line}#{column_column}: "
      if /\n/ =~ nearest
        snippet = "%#{Math.log10(@line).truncate}d" % (@line - 1)
        snippet << " " * column_column.size
        snippet << ": "
        snippet << nearest.gsub(/\n/, "\n#{target_position_info}")
      else
        snippet = "#{target_position_info}#{nearest}"
      end
      snippet
    end

    def numbered_ldif
      return @ldif if @ldif.blank?
      lines = Compatible.string_to_lines(@ldif)
      format = "%#{Math.log10(lines.size).truncate + 1}d: %s"
      i = 0
      lines.collect do |line|
        i += 1
        format % [i, line]
      end.join
    end
  end

  class EntryNotSaved < Error
  end

  class RequiredObjectClassMissed < Error
  end

  class RequiredAttributeMissed < Error
  end

  class EntryInvalid < Error
    attr_reader :entry
    def initialize(entry)
      @entry = entry
      errors = @entry.errors.full_messages.join(", ")
      super(errors)
    end
  end

  class OperationNotPermitted < Error
  end

  class ConnectionNotSetup < Error
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

  class AttributeValueInvalid < Error
    attr_reader :attribute, :value
    def initialize(attribute, value, message)
      @attribute = attribute
      @value = value
      super(message)
    end
  end

  class NotImplemented < Error
    attr_reader :target
    def initialize(target)
      @target = target
      super(_("not implemented: %s") % @target)
    end
  end

  # Base
  #
  # Base is the primary class which contains all of the core
  # ActiveLdap functionality. It is meant to only ever be subclassed
  # by extension classes.
  class Base
    include GetTextSupport
    public :_

    if Object.const_defined?(:Reloadable)
      if Reloadable.const_defined?(:Deprecated)
        include Reloadable::Deprecated
      else
        include Reloadable::Subclasses
      end
    end

    cattr_accessor :colorize_logging, :instance_writer => false
    @@colorize_logging = true

    VALID_LDAP_MAPPING_OPTIONS = [:dn_attribute, :prefix, :scope,
                                  :classes, :recommended_classes,
                                  :excluded_classes, :sort_by, :order]

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
        EOS
      end
    end

    class_local_attr_accessor false, :inheritable_prefix, :inheritable_base
    class_local_attr_accessor true, :dn_attribute, :scope, :sort_by, :order
    class_local_attr_accessor true, :required_classes, :recommended_classes
    class_local_attr_accessor true, :excluded_classes

    class << self
      # Hide new in Base
      private :new

      def inherited(sub_class)
        super
        sub_class.module_eval do
          include GetTextSupport
        end
      end

      # Set LDAP connection configuration up. It doesn't connect
      # and bind to LDAP server. A connection to LDAP server is
      # created when it's needed.
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
      # See lib/active_ldap/configuration.rb for defaults for each option
      def setup_connection(config=nil)
        super
        ensure_logger
        nil
      end

      # establish_connection is deprecated since 1.1.0. Please use
      # setup_connection() instead.
      def establish_connection(config=nil)
        message =
          _("ActiveLdap::Base.establish_connection has been deprecated " \
            "since 1.1.0. " \
            "Please use ActiveLdap::Base.setup_connection instead.")
        ActiveSupport::Deprecation.warn(message)
        setup_connection(config)
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
        self.dn_attribute = dn_attribute.to_s if dn_attribute.is_a?(Symbol)
        self.prefix = options[:prefix] || default_prefix
        self.scope = options[:scope]
        self.required_classes = options[:classes]
        self.recommended_classes = options[:recommended_classes]
        self.excluded_classes = options[:excluded_classes]
        self.sort_by = options[:sort_by]
        self.order = options[:order]

        public_class_method :new
      end

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
        @base ||= compute_base
      end
      alias_method :parsed_base, :base # for backward compatibility

      def base=(value)
        self.inheritable_base = value
        @base = nil
      end

      def prefix
        @prefix ||= inheritable_prefix and DN.parse(inheritable_prefix)
      end

      def prefix=(value)
        self.inheritable_prefix = value
        @prefix = nil
        @base = nil
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

      def inspect
        if self == Base
          super
        elsif abstract_class?
          "#{super}(abstract)"
        else
          detail = nil
          begin
            must = []
            may = []
            class_names = classes.collect do |object_class|
              must.concat(object_class.must)
              may.concat(object_class.may)
              object_class.name
            end
            detail = ["objectClass:<#{class_names.join(', ')}>",
                      "must:<#{inspect_attributes(must)}>",
                      "may:<#{inspect_attributes(may)}>"].join(", ")
          rescue ActiveLdap::ConnectionNotSetup
            detail = "not-connected"
          rescue ActiveLdap::Error
            detail = "connection-failure"
          end
          "#{super}(#{detail})"
        end
      end

      attr_accessor :abstract_class
      def abstract_class?
        defined?(@abstract_class) && @abstract_class
      end

      def class_of_active_ldap_descendant(klass)
        if klass.superclass == Base or klass.superclass.abstract_class?
          klass
        elsif klass.superclass.nil?
          raise Error, _("%s doesn't belong in a hierarchy descending " \
                         "from ActiveLdap") % (name || to_s)
        else
          class_of_active_ldap_descendant(klass.superclass)
        end
      end

      def self_and_descendants_from_active_ldap
        klass = self
        classes = [klass]
        while klass != klass.base_class
          classes << klass = klass.superclass
        end
        classes
      rescue
        [self]
      end

      def human_name(options={})
        defaults = self_and_descendants_from_active_ldap.collect do |klass|
          if klass.name.blank?
            nil
          else
            :"#{klass.name.underscore}"
          end
        end
        defaults << name.humanize
        defaults = defaults.compact
        defaults.first || name || to_s
      end

      private
      def inspect_attributes(attributes)
        inspected_attribute_names = {}
        attributes.collect do |attribute|
          if inspected_attribute_names.has_key?(attribute.name)
            nil
          else
            inspected_attribute_names[attribute.name] = true
            inspect_attribute(attribute)
          end
        end.compact.join(', ')
      end

      def inspect_attribute(attribute)
        syntax = attribute.syntax
        result = "#{attribute.name}"
        if syntax and !syntax.description.blank?
          result << ": #{syntax.description}"
        end
        properties = []
        properties << "read-only" if attribute.read_only?
        properties << "binary" if attribute.binary?
        properties << "binary-required" if attribute.binary_required?
        result << "(#{properties.join(', ')})" unless properties.empty?
        result
      end

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
          @@logger.level = Logger::ERROR
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
        dn_attribute = nil
        parent_class = ancestors[1]
        if parent_class.respond_to?(:dn_attribute)
          dn_attribute = parent_class.dn_attribute
        end
        dn_attribute || "cn"
      end

      def default_prefix
        if name.blank?
          nil
        else
          "ou=#{name.demodulize.pluralize}"
        end
      end

      def compute_base
        _base = inheritable_base
        _base = configuration[:base] if _base.nil? and configuration
        if _base.nil?
          target = superclass
          loop do
            break unless target.respond_to?(:base)
            _base = target.base
            break if _base
            target = target.superclass
          end
        end
        _prefix = prefix

        _base ||= connection.naming_contexts.first
        return _prefix if _base.blank?

        _base = DN.parse(_base)
        _base = _prefix + _base if _prefix
        _base
      end
    end

    self.scope = :sub
    self.required_classes = ['top']
    self.recommended_classes = []
    self.excluded_classes = []

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
      case attributes
      when nil
        self.classes = initial_classes
      when String, Array, DN
        self.classes = initial_classes
        self.dn = attributes
      when Hash
        classes, attributes = extract_object_class(attributes)
        self.classes = classes | initial_classes
        normalized_attributes = {}
        attributes.each do |key, value|
          real_key = to_real_attribute_name(key) || key
          normalized_attributes[real_key] = value
        end
        self.dn = normalized_attributes.delete(dn_attribute)
        self.attributes = normalized_attributes
      else
        format = _("'%s' must be either nil, DN value as ActiveLdap::DN, " \
                   "String or Array or attributes as Hash")
        raise ArgumentError, format % attributes.inspect
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
      return super if @_hashing # workaround for GetText :<
      _dn = nil
      begin
        @_hashing = true
        _dn = dn
      rescue DistinguishedNameInvalid, DistinguishedNameNotSetError
        return super
      ensure
        @_hashing = false
      end
      _dn.hash
    end

    def may
      entry_attribute.may
    end

    def must
      entry_attribute.must
    end

    # attributes
    #
    # Return attribute methods so that a program can determine available
    # attributes dynamically without schema awareness
    def attribute_names(normalize=false)
      entry_attribute.names(normalize)
    end

    def attribute_present?(name)
      values = get_attribute(name, true)
      !values.empty? or values.any? {|x| !(x and x.empty?)}
    end

    # exist?
    #
    # Return whether the entry exists in LDAP or not
    def exist?
      self.class.exists?(dn)
    end
    alias_method(:exists?, :exist?)

    # dn
    #
    # Return the authoritative dn
    def dn
      @dn ||= compute_dn
    end

    def id
      get_attribute(dn_attribute_with_fallback)
    end

    def to_param
      id
    end

    # Returns this entity’s dn wrapped in an Array or nil if the entity' s dn is not set.
    def to_key
      [dn]
    rescue DistinguishedNameNotSetError
      nil
    end

    def dn=(value)
      set_attribute(dn_attribute_with_fallback, value)
    end
    alias_method(:id=, :dn=)

    alias_method(:dn_attribute_of_class, :dn_attribute)
    def dn_attribute
      ensure_update_dn
      _dn_attribute = @dn_attribute || dn_attribute_of_class
      to_real_attribute_name(_dn_attribute) || _dn_attribute
    end

    def default_search_attribute
      self.class.default_search_attribute
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
      @simplified_data ||= simplify_data(@data)
      @simplified_data.clone
    end

    # This allows a bulk update to the attributes of a record
    # without forcing an immediate save or validation.
    #
    # It is unwise to attempt objectClass updates this way.
    # Also be sure to only pass in key-value pairs of your choosing.
    # Do not let URL/form hackers supply the keys.
    def attributes=(new_attributes)
      return if new_attributes.blank?
      assign_attributes(new_attributes)
    end

    def assign_attributes(new_attributes, options={})
      return if new_attributes.blank?

      _schema = _local_entry_attribute = nil
      if options[:without_protection]
        targets = new_attributes
      else
        targets = sanitize_for_mass_assignment(new_attributes, options[:role])
      end
      targets.each do |key, value|
        setter = "#{key}="
        unless respond_to?(setter)
          _schema ||= schema
          attribute = _schema.attribute(key)
          next if attribute.id.nil?
          _local_entry_attribute ||= local_entry_attribute
          _local_entry_attribute.register(attribute)
        end
        send(setter, value)
      end
    end

    def to_ldif_record
      super(dn, normalize_data(@data))
    end

    def to_ldif
      Ldif.new([to_ldif_record]).to_s
    end

    def to_xml(options={})
      options = options.dup
      options[:root] ||= (self.class.name || '').underscore
      options[:root] = 'anonymous' if options[:root].blank?
      [:only, :except].each do |attribute_names_key|
        names = options[attribute_names_key]
        next if names.nil?
        options[attribute_names_key] = names.collect do |name|
          if name.to_s.downcase == "dn"
            "dn"
          else
            to_real_attribute_name(name)
          end
        end.compact
      end
      XML.new(dn, normalize_data(@data), schema).to_s(options)
    end

    def to_s
      to_ldif
    end

    def have_attribute?(name, except=[])
      real_name = to_real_attribute_name(name)
      !real_name.nil? and !except.include?(real_name)
    end
    alias_method :has_attribute?, :have_attribute?

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

    def bind(config_or_password={}, config_or_ignore=nil, &block)
      if config_or_password.is_a?(String)
        config = (config_or_ignore || {}).merge(:password => config_or_password)
      else
        config = config_or_password
      end
      config = {:bind_dn => dn, :allow_anonymous => false}.merge(config)
      config[:password_block] ||= block if block_given?
      setup_connection(config)

      before_connection = @connection
      begin
        @connection = nil
        connection.connect
        @connection = connection
        clear_connection_based_cache
        clear_association_cache
      rescue ActiveLdap::Error
        remove_connection
        @connection = before_connection
        raise
      end
      true
    end

    def clear_connection_based_cache
      @schema = nil
      @local_entry_attribute = nil
      clear_object_class_based_cache
    end

    def clear_object_class_based_cache
      @entry_attribute = nil
      @real_names = {}
    end

    def schema
      @schema ||= super
    end

    def base
      @base ||= compute_base
    end

    def base=(object_local_base)
      ensure_update_dn
      @dn = nil
      @base = nil
      @base_value = object_local_base
    end

    alias_method :scope_of_class, :scope
    def scope
      @scope || scope_of_class
    end

    def scope=(scope)
      self.class.validate_scope(scope)
      @scope = scope
    end

    def delete_all(options={})
      super({:base => dn}.merge(options || {}))
    end

    def destroy_all(options={})
      super({:base => dn}.merge(options || {}))
    end

    def inspect
      object_classes = entry_attribute.object_classes
      inspected_object_classes = object_classes.collect do |object_class|
        object_class.name
      end.join(', ')
      must_attributes = must.collect(&:name).sort.join(', ')
      may_attributes = may.collect(&:name).sort.join(', ')
      inspected_attributes = attribute_names.sort.collect do |name|
        inspect_attribute(name)
      end.join(', ')
      result = "\#<#{self.class} objectClass:<#{inspected_object_classes}>, "
      result << "must:<#{must_attributes}>, may:<#{may_attributes}>, "
      result << "#{inspected_attributes}>"
      result
    end

    private
    def dn_attribute_with_fallback
      begin
        dn_attribute
      rescue DistinguishedNameInvalid
        _dn_attribute = @dn_attribute || dn_attribute_of_class
        _dn_attribute = to_real_attribute_name(_dn_attribute) || _dn_attribute
        raise if _dn_attribute.nil?
        _dn_attribute
      end
    end

    def inspect_attribute(name)
      values = get_attribute(name, true)
      values.collect do |value|
        if value.is_a?(String) and value.length > 50
          "#{value[0, 50]}...".inspect
        elsif value.is_a?(Date) || value.is_a?(Time)
          "#{value.to_s(:db)}"
        else
          value.inspect
        end
      end
      "#{name}: #{values.inspect}"
    end

    def find_object_class_values(data)
      data["objectClass"] || data["objectclass"]
    end

    def attribute_name_resolvable_without_connection?
      @entry_attribute and @local_entry_attribute
    end

    def entry_attribute
      @entry_attribute ||=
        connection.entry_attribute(find_object_class_values(@data) || [])
    end

    def local_entry_attribute
      @local_entry_attribute ||= connection.entry_attribute([])
    end

    def extract_object_class(attributes)
      classes = []
      attrs = {}
      attributes.each do |key, value|
        key = key.to_s
        if /\Aobject_?class\z/i =~ key
          classes.concat(value.to_a)
        else
          attrs[key] = value
        end
      end
      [classes, attributes]
    end

    def init_base
      init_instance_variables
    end

    def initialize_by_ldap_data(dn, attributes)
      init_base
      dn = Compatible.convert_to_utf8_encoded_object(dn)
      attributes = Compatible.convert_to_utf8_encoded_object(attributes)
      @original_dn = dn.clone
      @dn = dn
      @base = nil
      @base_value = nil
      @new_entry = false
      @dn_is_base = false
      @ldap_data = attributes
      classes, attributes = extract_object_class(attributes)
      self.classes = classes
      self.dn = dn
      initialize_attributes(attributes)
      yield self if block_given?
    end

    def initialize_attributes(attributes)
      _schema = _local_entry_attribute = nil
      targets = sanitize_for_mass_assignment(attributes)
      targets.each do |key, value|
        unless have_attribute?(key)
          _schema ||= schema
          attribute = _schema.attribute(key)
          _local_entry_attribute ||= local_entry_attribute
          _local_entry_attribute.register(attribute)
        end
        set_attribute(key, value)
      end
    end
    private :initialize_attributes

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

    def to_real_attribute_name(name, allow_normalized_name=true)
      return name if name.nil?
      if allow_normalized_name
        entry_attribute.normalize(name, allow_normalized_name) ||
          local_entry_attribute.normalize(name, allow_normalized_name)
      else
        @real_names[name] ||=
          entry_attribute.normalize(name, false) ||
          local_entry_attribute.normalize(name, false)
      end
    end

    # enforce_type
    #
    # enforce_type applies your changes without attempting to write to LDAP.
    # This means that if you set userCertificate to somebinary value, it will
    # wrap it up correctly.
    def enforce_type(key, value)
      # Enforce attribute value formatting
      normalize_attribute(key, value)[1]
    end

    def init_instance_variables
      @mutex = Mutex.new
      @data = {} # where the r/w entry data is stored
      @ldap_data = {} # original ldap entry data
      @dn_attribute = nil
      @base = nil
      @scope = nil
      @dn = nil
      @dn_is_base = false
      @dn_split_value = nil
      @connection ||= nil
      @_hashing = false
      clear_connection_based_cache
    end

    def register_new_dn_attribute(name, value)
      @dn = nil
      @dn_is_base = false
      if value.blank?
        @dn_split_value = nil
        [name, nil]
      else
        new_name, new_value, raw_new_value, new_bases = split_dn_value(value)
        @dn_split_value = [new_name, new_value, new_bases]
        if new_name.nil? and new_value.nil?
          new_name, raw_new_value = new_bases[0].to_a[0]
        end
        [to_real_attribute_name(new_name) || name,
         raw_new_value || value]
      end
    end

    def update_dn(new_name, new_value, bases)
      if new_name.nil? and new_value.nil?
        @dn_is_base = true
        @base = nil
        @base_value = nil
        attr, value = bases[0].to_a[0]
        @dn_attribute = attr
        _ = value # for suppress a warning on Ruby 1.9.3
      else
        new_name ||= @dn_attribute || dn_attribute_of_class
        new_name = to_real_attribute_name(new_name)
        if new_name.nil?
          new_name = @dn_attribute || dn_attribute_of_class
          new_name = to_real_attribute_name(new_name)
        end
        new_bases = bases.empty? ? nil : DN.new(*bases).to_s
        dn_components = ["#{new_name}=#{new_value}",
                         new_bases,
                         self.class.base.to_s]
        dn_components = dn_components.find_all {|component| !component.blank?}
        DN.parse(dn_components.join(','))
        @base = nil
        @base_value = new_bases
        @dn_attribute = new_name
      end
    end

    def split_dn_value(value)
      dn_value = relative_dn_value = nil
      begin
        dn_value = value if value.is_a?(DN)
        dn_value ||= DN.parse(value)
      rescue DistinguishedNameInvalid
        begin
          dn_value = DN.parse("#{dn_attribute}=#{value}")
        rescue DistinguishedNameInvalid
          return [nil, value, value, []]
        end
      end

      val = bases = nil
      begin
        relative_dn_value = dn_value
        base_of_class = self.class.base
        relative_dn_value -= base_of_class if base_of_class
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
      escaped_dn_attribute_value = nil
      unless dn_attribute_value.nil?
        escaped_dn_attribute_value = DN.escape_value(dn_attribute_value)
      end
      [dn_attribute_name, escaped_dn_attribute_value,
       dn_attribute_value, bases]
    end

    def need_update_dn?
      not @dn_split_value.nil?
    end

    def ensure_update_dn
      return unless need_update_dn?
      @mutex.synchronize do
        if @dn_split_value
          update_dn(*@dn_split_value)
          @dn_split_value = nil
        end
      end
    end

    def compute_dn
      return base if @dn_is_base

      ensure_update_dn
      dn_value = id
      if dn_value.nil?
        format = _("%s's DN attribute (%s) isn't set")
        message = format % [self.inspect, dn_attribute]
        raise DistinguishedNameNotSetError.new, message
      end
      dn_value = DN.escape_value(dn_value.to_s)
      _base = base
      _base = nil if _base.blank?
      DN.parse(["#{dn_attribute}=#{dn_value}", _base].compact.join(","))
    end

    def compute_base
      base_of_class = self.class.base
      if @base_value.nil?
        base_of_class
      else
        base_of_object = DN.parse(@base_value)
        base_of_object += base_of_class if base_of_class
        base_of_object
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
          value.collect {|v| array_of(v, false)}.compact
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
        to_a ? [value] : value
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
        result[real_name].concat(enforce_type(real_name, values))
      end
      result
    end

    def simplify_data(data)
      _schema = schema
      result = {}
      data.each do |key, values|
        attribute = _schema.attribute(key)
        if attribute.single_value? and values.is_a?(Array) and values.size == 1
          values = values[0]
        end
        result[key] = type_cast(attribute, values)
      end
      result
    end

    def collect_modified_attributes(ldap_data, data)
      klass = self.class
      _dn_attribute = dn_attribute
      new_dn_value = nil
      attributes = []

      # Now that all the options will be treated as unique attributes
      # we can see what's changed and add anything that is brand-spankin'
      # new.
      ldap_data.each do |k, v|
        value = data[k] || []

        next if v == value

        value = klass.remove_blank_value(value) || []
        next if v == value

        if klass.blank_value?(value) and
            schema.attribute(k).binary_required?
          value = [{'binary' => []}]
        end
        if k == _dn_attribute
          new_dn_value = value[0]
        else
          attributes.push([:replace, k, value])
        end
      end

      data.each do |k, v|
        value = v || []
        next if ldap_data.has_key?(k)

        value = klass.remove_blank_value(value) || []
        next if klass.blank_value?(value)

        # Detect subtypes and account for them
        # REPLACE will function like ADD, but doesn't hit EQUALITY problems
        # TODO: Added equality(attr) to Schema
        attributes.push([:replace, k, value])
      end

      [new_dn_value, attributes]
    end

    def collect_all_attributes(data)
      dn_attr = dn_attribute
      dn_value = data[dn_attr]

      attributes = []
      attributes.push([dn_attr, dn_value])

      oc_value = data['objectClass']
      attributes.push(['objectClass', oc_value])
      except_keys = ['objectClass', dn_attr].collect(&:downcase)
      data.each do |key, value|
        next if except_keys.include?(key.downcase)
        value = self.class.remove_blank_value(value)
        next if self.class.blank_value?(value)

        attributes.push([key, value])
      end

      attributes
    end

    def prepare_data_for_saving
      # Expand subtypes to real ldap_data attributes
      # We can't reuse @ldap_data because an exception would leave
      # an object in an unknown state
      ldap_data = normalize_data(@ldap_data)

      # Expand subtypes to real data attributes, but leave @data alone
      object_classes = find_object_class_values(@ldap_data) || []
      original_attributes =
        connection.entry_attribute(object_classes).names
      bad_attrs = original_attributes - entry_attribute.names
      data = normalize_data(@data, bad_attrs)

      success = yield(data, ldap_data)

      if success
        @ldap_data = data.clone
        # Delete items disallowed by objectclasses.
        # They should have been removed from ldap.
        bad_attrs.each do |remove_me|
          @ldap_data.delete(remove_me)
        end
        @original_dn = dn.clone
      end

      success
    end
  end # Base
end # ActiveLdap
