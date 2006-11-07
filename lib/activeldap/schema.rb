module ActiveLDAP
  class Schema
    def initialize(entries)
      @entries = entries
      @schema_info = {}
      @class_attributes_info = {}
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

    def attributes(group, id_or_name)
      return {} if group.empty? or id_or_name.empty?

      # Initialize anything that is required
      info, ids, aliases = ensure_schema_info(group)
      id, name = determine_id_or_name(id_or_name, aliases)

      # Check already parsed options first
      return ids[id] if ids.has_key?(id)

      while schema = @entries[group].shift
        next unless /\A\s*\(\s*([\d\.]+)\s*(.*)\s*\)\s*\z/ =~ schema
        schema_id = $1
        rest = $2
        next if ids.has_key?(schema_id)

        attributes = {}
        ids[schema_id] = attributes

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
      attribute_type(name, 'NAME')
    end

    # read_only?
    #
    # Returns true if an attribute is read-only
    # NO-USER-MODIFICATION
    def read_only?(name)
      attribute_type(name, 'NO-USER-MODIFICATION')[0] == 'TRUE'
    end

    # single_value?
    #
    # Returns true if an attribute can only have one
    # value defined
    # SINGLE-VALUE
    def single_value?(name)
      attribute_type(name, 'SINGLE-VALUE')[0] == 'TRUE'
    end

    # binary?
    #
    # Returns true if the given attribute's syntax
    # is X-NOT-HUMAN-READABLE or X-BINARY-TRANSFER-REQUIRED
    def binary?(name)
      # Get syntax OID
      syntax = attribute_type(name, 'SYNTAX')[0]
      !syntax.nil? and
        (ldap_syntax(syntax, 'X-NOT-HUMAN-READABLE') == ["TRUE"] or
         ldap_syntax(syntax, 'X-BINARY-TRANSFER-REQUIRED') == ["TRUE"])
    end

    # binary_required?
    #
    # Returns true if the value MUST be transferred in binary
    def binary_required?(name)
      # Get syntax OID
      syntax = attribute_type(name, 'SYNTAX')[0]
      !syntax.nil? and
        ldap_syntax(syntax, 'X-BINARY-TRANSFER-REQUIRED') == ["TRUE"]
    end

    # class_attributes
    #
    # Returns an Array of all the valid attributes (but not with full aliases)
    # for the given objectClass
    def class_attributes(objc)
      if @class_attributes_info.has_key?(objc)
        return @class_attributes_info[objc].dup
      end

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

      @class_attributes_info[objc] = info = {:must => must, :may => may}

      # Return the cached value
      return info.dup
    end

    private
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

    def parse_attributes(str, attributes)
      str.scan(/([A-Z\-]+)\s+
                (?:\(\s*([\w\-]+(?:\s+\$\s+[\w\-]+)+)\s*\)|
                   \(\s*([^\)]*)\s*\)|
                   '([^\']*)'|
                   ([a-z][\w\-]*)|
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
        attributes[name] = values
      end
    end

    def attribute_type(name, attribute_name)
      attribute("attributeTypes", name, attribute_name)
    end

    def ldap_syntax(name, attribute_name)
      attribute("ldapSyntaxes", name, attribute_name)
    end

    def object_class(name, attribute_name)
      attribute("objectClasses", name, attribute_name)
    end

    def alias_map(group)
      ensure_parse(group)
      @schema_info[group][:aliases]
    end

    def ensure_parse(group)
      unless @entries[group].empty?
        attribute(group, 'nonexistent', 'nonexistent')
      end
    end

    def normalize_schema_name(name)
      name.downcase.sub(/;.*$/, '')
    end

    def normalize_attribute_name(name)
      name.upcase
    end
  end # Schema
end
