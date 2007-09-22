module ActiveLdap
  class Schema
    def initialize(entries)
      @entries = default_entries.merge(entries || {})
      @schema_info = {}
      @class_attributes_info = {}
      @cache = {}
    end

    def ids(group)
      ensure_parse(group)
      info, ids, aliases = ensure_schema_info(group)
      ids.keys
    end

    def names(group)
      alias_map(group).keys
    end

    def exist_name?(group, name)
      alias_map(group).has_key?(normalize_schema_name(name))
    end

    def resolve_name(group, name)
      alias_map(group)[normalize_schema_name(name)]
    end

    # fetch
    #
    # This is just like LDAP::Schema#attribute except that it allows
    # look up in any of the given keys.
    # e.g.
    #  fetch('attributeTypes', 'cn', 'DESC')
    #  fetch('ldapSyntaxes', '1.3.6.1.4.1.1466.115.121.1.5', 'DESC')
    def fetch(group, id_or_name, attribute_name)
      return [] if attribute_name.empty?
      attribute_name = normalize_attribute_name(attribute_name)
      value = entry(group, id_or_name)[attribute_name]
      value ? value.dup : []
    end
    alias_method :[], :fetch

    NUMERIC_OID_RE = "\\d[\\d\\.]+"
    DESCRIPTION_RE = "[a-zA-Z][a-zA-Z\\d\\-]*"
    OID_RE = "(?:#{NUMERIC_OID_RE}|#{DESCRIPTION_RE}-oid)"
    def entry(group, id_or_name)
      return {} if group.empty? or id_or_name.empty?

      unless @entries.has_key?(group)
        raise ArgumentError, _("Unknown schema group: %s") % group
      end

      # Initialize anything that is required
      info, ids, aliases = ensure_schema_info(group)
      id, name = determine_id_or_name(id_or_name, aliases)

      # Check already parsed options first
      return ids[id] if ids.has_key?(id)

      schemata = @entries[group] || []
      while schema = schemata.shift
        next unless /\A\s*\(\s*(#{OID_RE})\s*(.*)\s*\)\s*\z/ =~ schema
        schema_id = $1
        rest = $2

        if ids.has_key?(schema_id)
          attributes = ids[schema_id]
        else
          attributes = {}
          ids[schema_id] = attributes
        end

        parse_attributes(rest, attributes)
        (attributes["NAME"] || []).each do |v|
          normalized_name = normalize_schema_name(v)
          aliases[normalized_name] = schema_id
          id = schema_id if id.nil? and name == normalized_name
        end

        break if id == schema_id
      end

      ids[id || aliases[name]] || {}
    end

    def attribute(name)
      cache([:attribute, name]) do
        Attribute.new(name, self)
      end
    end

    def attributes
      cache([:attributes]) do
        names("attributeTypes").collect do |name|
          attribute(name)
        end
      end
    end

    def attribute_type(name, attribute_name)
      cache([:attribute_type, name, attribute_name]) do
        fetch("attributeTypes", name, attribute_name)
      end
    end

    def object_class(name)
      cache([:object_class, name]) do
        ObjectClass.new(name, self)
      end
    end

    def object_classes
      cache([:object_classes]) do
        names("objectClasses").collect do |name|
          object_class(name)
        end
      end
    end

    def object_class_attribute(name, attribute_name)
      cache([:object_class_attribute, name, attribute_name]) do
        fetch("objectClasses", name, attribute_name)
      end
    end

    def ldap_syntax(name)
      cache([:ldap_syntax, name]) do
        Syntax.new(name, self)
      end
    end

    def ldap_syntaxes
      cache([:ldap_syntaxes]) do
        ids("ldapSyntaxes").collect do |id|
          ldap_syntax(id)
        end
      end
    end

    def ldap_syntax_attribute(name, attribute_name)
      cache([:ldap_syntax_attribute, name, attribute_name]) do
        fetch("ldapSyntaxes", name, attribute_name)
      end
    end

    private
    def cache(key)
      (@cache[key] ||= [yield])[0]
    end

    def ensure_schema_info(group)
      @schema_info[group] ||= {:ids => {}, :aliases => {}}
      info = @schema_info[group]
      [info, info[:ids], info[:aliases]]
    end

    def determine_id_or_name(id_or_name, aliases)
      if /\A[\d\.]+\z/ =~ id_or_name
        id = id_or_name
        name = nil
      else
        name = normalize_schema_name(id_or_name)
        id = aliases[name]
      end
      [id, name]
    end

    # from RFC 2252
    attribute_type_description_reserved_names =
      ["NAME", "DESC", "OBSOLETE", "SUP", "EQUALITY", "ORDERING", "SUBSTR",
       "SYNTAX", "SINGLE-VALUE", "COLLECTIVE", "NO-USER-MODIFICATION", "USAGE"]
    syntax_description_reserved_names = ["DESC"]
    object_class_description_reserved_names =
      ["NAME", "DESC", "OBSOLETE", "SUP", "ABSTRACT", "STRUCTURAL",
       "AUXILIARY", "MUST", "MAY"]
    matching_rule_description_reserved_names =
      ["NAME", "DESC", "OBSOLETE", "SYNTAX"]
    matching_rule_use_description_reserved_names =
      ["NAME", "DESC", "OBSOLETE", "APPLIES"]
    private_experiment_reserved_names = ["X-[A-Z\\-_]+"]
    reserved_names =
      (attribute_type_description_reserved_names +
       syntax_description_reserved_names +
       object_class_description_reserved_names +
       matching_rule_description_reserved_names +
       matching_rule_use_description_reserved_names +
       private_experiment_reserved_names).uniq
    RESERVED_NAMES_RE = /(?:#{reserved_names.join('|')})/

    def parse_attributes(str, attributes)
      str.scan(/([A-Z\-_]+)\s+
                (?:\(\s*([\w\-]+(?:\s+\$\s+[\w\-]+)+)\s*\)|
                   \(\s*([^\)]*)\s*\)|
                   '([^\']*)'|
                   ((?!#{RESERVED_NAMES_RE})[a-zA-Z][a-zA-Z\d\-;]*)|
                   (\d[\d\.\{\}]+)|
                   ()
                )/x
               ) do |name, multi_amp, multi, string, literal, syntax, no_value|
        case
        when multi_amp
          values = multi_amp.rstrip.split(/\s*\$\s*/)
        when multi
          values = multi.scan(/\s*'([^\']*)'\s*/).collect {|value| value[0]}
        when string
          values = [string]
        when literal
          values = [literal]
        when syntax
          values = [syntax]
        when no_value
          values = ["TRUE"]
        end
        attributes[normalize_attribute_name(name)] ||= []
        attributes[normalize_attribute_name(name)].concat(values)
      end
    end

    def alias_map(group)
      ensure_parse(group)
      return {} if @schema_info[group].nil?
      @schema_info[group][:aliases] || {}
    end

    def ensure_parse(group)
      return if @entries[group].nil?
      unless @entries[group].empty?
        fetch(group, 'nonexistent', 'nonexistent')
      end
    end

    def normalize_schema_name(name)
      name.downcase.sub(/;.*$/, '')
    end

    def normalize_attribute_name(name)
      name.upcase.gsub(/_/, "-")
    end

    def default_entries
      {
        "objectClasses" => [],
        "attributeTypes" => [],
        "ldapSyntaxes" => [],
      }
    end

    class Entry
      include Comparable

      attr_reader :id, :name, :aliases, :description
      def initialize(name, schema, group)
        @schema = schema
        @name, *@aliases = attribute("NAME", name)
        @name ||= name
        @id = @schema.resolve_name(group, @name)
        collect_info
        @schema = nil
      end

      def eql?(other)
        self.class == other.class and
          id == other.id
      end

      def hash
        id.hash
      end

      def <=>(other)
        name <=> other.name
      end
    end

    class Syntax < Entry
      def initialize(id, schema)
        super(id, schema, "ldapSyntaxes")
        @id = id
        @name = nil if @name == @id
        @validator = Syntaxes[@id]
      end

      def binary_transfer_required?
        @binary_transfer_required
      end

      def human_readable?
        @human_readable
      end

      def valid?(value)
        validate(value).nil?
      end

      def validate(value)
        if @validator
          @validator.validate(value)
        else
          nil
        end
      end

      def type_cast(value)
        if @validator
          @validator.type_cast(value)
        else
          value
        end
      end

      private
      def attribute(attribute_name, name=@name)
        @schema.ldap_syntax_attribute(name, attribute_name)
      end

      def collect_info
        @description = attribute("DESC")[0]
        @binary_transfer_required =
          (attribute('X-BINARY-TRANSFER-REQUIRED')[0] == 'TRUE')
        @human_readable = (attribute('X-NOT-HUMAN-READABLE')[0] != 'TRUE')
      end
    end

    class Attribute < Entry
      attr_reader :super_attribute
      def initialize(name, schema)
        super(name, schema, "attributeTypes")
      end

      # read_only?
      #
      # Returns true if an attribute is read-only
      # NO-USER-MODIFICATION
      def read_only?
        @read_only
      end

      # single_value?
      #
      # Returns true if an attribute can only have one
      # value defined
      # SINGLE-VALUE
      def single_value?
        @single_value
      end

      # binary?
      #
      # Returns true if the given attribute's syntax
      # is X-NOT-HUMAN-READABLE or X-BINARY-TRANSFER-REQUIRED
      def binary?
        @binary
      end

      # binary_required?
      #
      # Returns true if the value MUST be transferred in binary
      def binary_required?
        @binary_required
      end

      def syntax
        (@derived_syntax ||= [derived_syntax])[0]
      end

      def valid?(value)
        validate(value).nil?
      end

      def validate(value)
        send_to_syntax(nil, :validate, value)
      end

      def syntax_description
        send_to_syntax(nil, :description)
      end

      private
      def attribute(attribute_name, name=@name)
        @schema.attribute_type(name, attribute_name)
      end

      def collect_info
        @description = attribute("DESC")[0]
        @super_attribute = attribute("SUP")[0]
        if @super_attribute
          @super_attribute = @schema.attribute(@super_attribute)
          @super_attribute = nil if @super_attribute.id.nil?
        end
        @read_only = attribute('NO-USER-MODIFICATION')[0] == 'TRUE'
        @single_value = attribute('SINGLE-VALUE')[0] == 'TRUE'
        @syntax = attribute("SYNTAX")[0]
        @syntax = @schema.ldap_syntax(@syntax) if @syntax
        if @syntax
          @binary_required = @syntax.binary_transfer_required?
          @binary = (@binary_required or !@syntax.human_readable?)
        else
          @binary_required = false
          @binary = false
        end
      end

      def derived_syntax
        return @syntax if @syntax
        return @super_attribute.syntax if @super_attribute
        nil
      end

      def send_to_syntax(default_value, method_name, *args)
        _syntax = syntax
        if _syntax
          _syntax.send(method_name, *args)
        else
          default_value
        end
      end
    end

    class ObjectClass < Entry
      attr_reader :super_classes
      def initialize(name, schema)
        super(name, schema, "objectClasses")
      end

      def super_class?(object_class)
        @super_classes.include?(object_class)
      end

      def must(include_super_class=true)
        if include_super_class
          @all_must
        else
          @must
        end
      end

      def may(include_super_class=true)
        if include_super_class
          @all_may
        else
          @may
        end
      end

      private
      def collect_info
        @description = attribute("DESC")[0]
        @super_classes = collect_super_classes
        @must, @may, @all_must, @all_may = collect_attributes
      end

      def collect_super_classes
        super_classes = attribute('SUP')
        loop do
          start_size = super_classes.size
          new_super_classes = []
          super_classes.each do |super_class|
            new_super_classes.concat(attribute('SUP', super_class))
          end

          super_classes.concat(new_super_classes)
          super_classes.uniq!
          break if super_classes.size == start_size
        end
        super_classes.collect do |name|
          @schema.object_class(name)
        end
      end

      def collect_attributes
        must = attribute('MUST').collect {|name| @schema.attribute(name)}
        may = attribute('MAY').collect {|name| @schema.attribute(name)}

        all_must = must.dup
        all_may = may.dup
        @super_classes.each do |super_class|
          all_must.concat(super_class.must(false))
          all_may.concat(super_class.may(false))
        end

        # Clean out the dupes.
        all_must.uniq!
        all_may.uniq!

        [must, may, all_must, all_may]
      end

      def attribute(attribute_name, name=@name)
        @schema.object_class_attribute(name, attribute_name)
      end
    end
  end
end

require 'active_ldap/schema/syntaxes'
