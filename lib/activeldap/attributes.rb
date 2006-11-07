module ActiveLDAP
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
          [name, send(handler, name, value,
                      schema.single_value?(name),
                      schema.binary_required?(name))]
        else
          [name, [value.to_s]]
        end
      end

      private
      def normalize_attribute_value_of_array(name, value, single, binary)
        if single and value.size > 1
          raise TypeError, "Attribute #{name} can only have a single value"
        end
        value.collect do |entry|
          if entry.class != Hash
            logger.debug {"coercing value for #{name} into a string " +
                          "because nested values exceeds a useful depth: " +
                          "#{entry.inspect} -> #{entry.to_s}"}
            entry = entry.to_s
          end
          normalize_attribute(name, entry)[1][0]
        end
      end

      def normalize_attribute_value_of_hash(name, value, single, binary)
        if value.keys.size > 1
          raise TypeError, "Hashes must have one key-value pair only."
        end
        unless value.keys[0].match(/^(lang-[a-z][a-z]*)|(binary)$/)
          logger.warn {"unknown subtype did not match lang-* or binary:" +
                       "#{value.keys[0]}"}
        end
        # Contents MUST be a String or an Array
        if value.keys[0] != 'binary' and binary
          suffix, real_value = extract_subtypes(value)
          value = make_subtypes(name + suffix + ';binary', real_value)
        end
        [value]
      end

      def normalize_attribute_value_of_string(name, value, single, binary)
        [binary ? {'binary' => value} : value]
      end

      def normalize_attribute_value_of_date(name, value, single, binary)
        new_value = sprintf('%.04d%.02d%.02d%.02d%.02d%.02d%s',
                            value.year, value.month, value.mday, 0, 0, 0,
                            '+0000')
        [binary ? {'binary' => new_value} : new_value]
      end

      def normalize_attribute_value_of_time(name, value, single, binary)
        new_value = sprintf('%.04d%.02d%.02d%.02d%.02d%.02d%s',
                            0, 0, 0, value.hour, value.min, value.sec,
                            value.zone)
        [binary ? {'binary' => new_value} : new_value]
      end

      def normalize_attribute_value_of_date_time(name, value, single, binary)
        new_value = sprintf('%.04d%.02d%.02d%.02d%.02d%.02d%s',
                            value.year, value.month, value.mday, value.hour,
                            value.min, value.sec, value.zone)
        [binary ? {'binary' => new_value} : new_value]
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
