module ActiveLdap
  module AttributeMethods
    module Read
      extend ActiveSupport::Concern

      private
      def attribute(attr, *args)
        return get_attribute(attr, args.first)
      end

      def _read_attribute(name)
        get_attribute(name)
      end

      # get_attribute
      #
      # Return the value of the attribute called by method_missing?
      def get_attribute(name, force_array=false)
        name, value = get_attribute_before_type_cast(name, force_array)
        return value if name.nil?
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
          if result.size == 1 and result.has_key?("binary")
            result["binary"]
          else
            result
          end
        when Array
          value.collect do |val|
            type_cast(attribute, val)
          end
        else
          attribute.type_cast(value)
        end
      end

    end
  end
end
