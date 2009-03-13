module ActiveLdap
  module Compatible
    module_function
    if "".respond_to?(:force_encoding)
      def convert_to_utf8_encoded_object(object)
        case object
        when Array
          object.collect {|element| convert_to_utf8_encoded_object(element)}
        when Hash
          encoded = {}
          object.each do |key, value|
            key = convert_to_utf8_encoded_object(key)
            value = convert_to_utf8_encoded_object(value)
            encoded[key] = value
          end
          encoded
        when String
          if object.respond_to?(:force_encoding)
            encoded = object.dup
            encoded.force_encoding("utf-8")
            unless encoded.valid_encoding?
              encoded.force_encoding(object.encoding)
            end
            encoded
          else
            object
          end
        else
          object
        end
      end
    else
      def convert_to_utf8_encoded_object(object)
        object
      end
    end
  end
end
