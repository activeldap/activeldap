module ActiveLdap
  module Attributes
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def attr_protected(*attributes)
        targets = attributes.collect {|attr| attr.to_s} - protected_attributes
        instance_variable_set("@attr_protected", targets)
      end

      def protected_attributes
        ancestors.inject([]) do |result, ancestor|
          result + (ancestor.instance_variable_get("@attr_protected") || [])
        end
      end

      def normalize_attribute_name(name)
        name.to_s.downcase
      end

      # Enforce typing:
      # Hashes are for subtypes
      # Arrays are for multiple entries
      def normalize_attribute(name, value)
        logger.debug {"stub: called normalize_attribute" +
                      "(#{name.inspect}, #{value.inspect})"}
        if name.nil?
          raise RuntimeError, 'The first argument, name, must not be nil. ' +
                              'Please report this as a bug!'
        end

        name = normalize_attribute_name(name)
        rubyish_class_name = to_rubyish_name(value.class.name)
        handler = "normalize_attribute_value_of_#{rubyish_class_name}"
        if respond_to?(handler, true)
          [name, send(handler, name, value)]
        else
          [name, [value.to_s]]
        end
      end

      def unnormalize_attributes(attributes)
        result = {}
        attributes.each do |name, values|
          unnormalize_attribute(name, values, result)
        end
        result
      end

      def unnormalize_attribute(name, values, result={})
        if values.empty?
          result[name] = []
        else
          values.each do |value|
            if value.is_a?(Hash)
              suffix, real_value = extract_subtypes(value)
              new_name = name + suffix
              result[new_name] ||= []
              result[new_name].concat(real_value)
            else
              result[name] ||= []
              result[name] << value.dup
            end
          end
        end
        result
      end

      private
      def normalize_attribute_value_of_array(name, value)
        if value.size > 1 and schema.single_value?(name)
          raise TypeError, "Attribute #{name} can only have a single value"
        end
        if value.empty?
          schema.binary_required?(name) ? [{'binary' => value}] : value
        else
          value.collect do |entry|
            normalize_attribute(name, entry)[1][0]
          end
        end
      end

      def normalize_attribute_value_of_hash(name, value)
        if value.keys.size > 1
          raise TypeError, "Hashes must have one key-value pair only."
        end
        unless value.keys[0].match(/^(lang-[a-z][a-z]*)|(binary)$/)
          logger.warn {"unknown subtype did not match lang-* or binary:" +
                       "#{value.keys[0]}"}
        end
        # Contents MUST be a String or an Array
        if !value.has_key?('binary') and schema.binary_required?(name)
          suffix, real_value = extract_subtypes(value)
          name, values = make_subtypes(name + suffix + ';binary', real_value)
          values
        else
          [value]
        end
      end

      def normalize_attribute_value_of_nil_class(name, value)
        schema.binary_required?(name) ? [{'binary' => []}] : []
      end

      def normalize_attribute_value_of_string(name, value)
        [schema.binary_required?(name) ? {'binary' => [value]} : value]
      end

      def normalize_attribute_value_of_date(name, value)
        new_value = sprintf('%.04d%.02d%.02d%.02d%.02d%.02d%s',
                            value.year, value.month, value.mday, 0, 0, 0,
                            '+0000')
        normalize_attribute_value_of_string(name, new_value)
      end

      def normalize_attribute_value_of_time(name, value)
        new_value = sprintf('%.04d%.02d%.02d%.02d%.02d%.02d%s',
                            0, 0, 0, value.hour, value.min, value.sec,
                            value.zone)
        normalize_attribute_value_of_string(name, new_value)
      end

      def normalize_attribute_value_of_date_time(name, value)
        new_value = sprintf('%.04d%.02d%.02d%.02d%.02d%.02d%s',
                            value.year, value.month, value.mday, value.hour,
                            value.min, value.sec, value.zone)
        normalize_attribute_value_of_string(name, new_value)
      end


      # make_subtypes
      #
      # Makes the Hashized value from the full attributename
      # e.g. userCertificate;binary => "some_bin"
      #      becomes userCertificate => {"binary" => "some_bin"}
      def make_subtypes(attr, value)
        logger.debug {"stub: called make_subtypes(#{attr.inspect}, " +
                      "#{value.inspect})"}
        return [attr, value] unless attr.match(/;/)

        ret_attr, *subtypes = attr.split(/;/)
        return [ret_attr, [make_subtypes_helper(subtypes, value)]]
      end

      # make_subtypes_helper
      #
      # This is a recursive function for building
      # nested hashed from multi-subtyped values
      def make_subtypes_helper(subtypes, value)
        logger.debug {"stub: called make_subtypes_helper" +
                      "(#{subtypes.inspect}, #{value.inspect})"}
        return value if subtypes.size == 0
        return {subtypes[0] => make_subtypes_helper(subtypes[1..-1], value)}
      end

      # extract_subtypes
      #
      # Extracts all of the subtypes from a given set of nested hashes
      # and returns the attribute suffix and the final true value
      def extract_subtypes(value)
        logger.debug {"stub: called extract_subtypes(#{value.inspect})"}
        subtype = ''
        ret_val = value
        if value.class == Hash
          subtype = ';' + value.keys[0]
          ret_val = value[value.keys[0]]
          subsubtype = ''
          if ret_val.class == Hash
            subsubtype, ret_val = extract_subtypes(ret_val)
          end
          subtype += subsubtype
        end
        ret_val = [ret_val] unless ret_val.class == Array
        return subtype, ret_val
      end
    end

    private
    def remove_attributes_protected_from_mass_assignment(targets)
      needless_attributes = {}
      self.class.protected_attributes.each do |name|
        needless_attributes[to_real_attribute_name(name)] = true
      end

      targets.collect do |key, value|
        [to_real_attribute_name(key), value]
      end.reject do |key, value|
        key.nil? or needless_attributes[key]
      end
    end
  end
end
