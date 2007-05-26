module ActiveLdap
  class Schema
    def initialize(entries)
      @entries = default_entries.merge(entries || {})
      @schema_info = {}
      @class_attributes_info = {}
      @cache = {}
    end

    def names(group)
      alias_map(group).keys
    end

    def exist_name?(group, name)
      alias_map(group).has_key?(normalize_schema_name(name))
    end

    # attribute
    #
    # This is just like LDAP::Schema#attribute except that it allows
    # look up in any of the given keys.
    # e.g.
    #  attribute('attributeTypes', 'cn', 'DESC')
    #  attribute('ldapSyntaxes', '1.3.6.1.4.1.1466.115.121.1.5', 'DESC')
    def attribute(group, id_or_name, attribute_name)
      return [] if attribute_name.empty?
      attribute_name = normalize_attribute_name(attribute_name)
      value = attributes(group, id_or_name)[attribute_name]
      value ? value.dup : []
    end
    alias_method :[], :attribute
    alias_method :attr, :attribute

    NUMERIC_OID_RE = "\\d[\\d\\.]+"
    DESCRIPTION_RE = "[a-zA-Z][a-zA-Z\\d\\-]*"
    OID_RE = "(?:#{NUMERIC_OID_RE}|#{DESCRIPTION_RE}-oid)"
    def attributes(group, id_or_name)
      return {} if group.empty? or id_or_name.empty?

      unless @entries.has_key?(group)
        raise ArgumentError, "Unknown schema group: #{group}"
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

    # attribute_aliases
    #
    # Returns all names from the LDAP schema for the
    # attribute given.
    def attribute_aliases(name)
      cache([:attribute_aliases, name]) do
        attribute_type(name, 'NAME')
      end
    end

    # read_only?
    #
    # Returns true if an attribute is read-only
    # NO-USER-MODIFICATION
    def read_only?(name)
      cache([:read_only?, name]) do
        attribute_type(name, 'NO-USER-MODIFICATION')[0] == 'TRUE'
      end
    end

    # single_value?
    #
    # Returns true if an attribute can only have one
    # value defined
    # SINGLE-VALUE
    def single_value?(name)
      cache([:single_value?, name]) do
        attribute_type(name, 'SINGLE-VALUE')[0] == 'TRUE'
      end
    end

    # binary?
    #
    # Returns true if the given attribute's syntax
    # is X-NOT-HUMAN-READABLE or X-BINARY-TRANSFER-REQUIRED
    def binary?(name)
      cache([:binary?, name]) do
        # Get syntax OID
        syntax = attribute_type(name, 'SYNTAX')[0]
        !syntax.nil? and
          (ldap_syntax(syntax, 'X-NOT-HUMAN-READABLE') == ["TRUE"] or
           ldap_syntax(syntax, 'X-BINARY-TRANSFER-REQUIRED') == ["TRUE"])
      end
    end

    # binary_required?
    #
    # Returns true if the value MUST be transferred in binary
    def binary_required?(name)
      cache([:binary_required?, name]) do
        # Get syntax OID
        syntax = attribute_type(name, 'SYNTAX')[0]
        !syntax.nil? and
          ldap_syntax(syntax, 'X-BINARY-TRANSFER-REQUIRED') == ["TRUE"]
      end
    end

    # class_attributes
    #
    # Returns an Array of all the valid attributes (but not with full aliases)
    # for the given objectClass
    def class_attributes(objc)
      cache([:class_attributes, objc]) do
        # First get all the current level attributes
        must = object_class(objc, 'MUST')
        may = object_class(objc, 'MAY')

        # Now add all attributes from the parent object (SUPerclasses)
        # Hopefully an iterative approach will be pretty speedy
        # 1. build complete list of SUPs
        # 2. Add attributes from each
        sups = object_class(objc, 'SUP')
        loop do
          start_size = sups.size
          new_sups = []
          sups.each do |sup|
            new_sups.concat(object_class(sup, 'SUP'))
          end

          sups.concat(new_sups)
          sups.uniq!
          break if sups.size == start_size
        end
        sups.each do |sup|
          must.concat(object_class(sup, 'MUST'))
          may.concat(object_class(sup, 'MAY'))
        end

        # Clean out the dupes.
        must.uniq!
        may.uniq!
        if objc == "inetOrgPerson"
          may.collect! do |name|
            if name == "x500uniqueIdentifier"
              "x500UniqueIdentifier"
            else
              name
            end
          end
        end

        {:must => must, :may => may}
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

    def attribute_type(name, attribute_name)
      cache([:attribute_type, name, attribute_name]) do
        attribute("attributeTypes", name, attribute_name)
      end
    end

    def ldap_syntax(name, attribute_name)
      return [] unless @entries.has_key?("ldapSyntaxes")
      cache([:ldap_syntax, name, attribute_name]) do
        attribute("ldapSyntaxes", name, attribute_name)
      end
    end

    def object_class(name, attribute_name)
      cache([:object_class, name, attribute_name]) do
        attribute("objectClasses", name, attribute_name)
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
        attribute(group, 'nonexistent', 'nonexistent')
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
  end # Schema
end
