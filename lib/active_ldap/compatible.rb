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
          encoded = object.dup
          encoded.force_encoding("utf-8")
          encoded = object unless encoded.valid_encoding?
          encoded
        else
          object
        end
      end
    else
      def convert_to_utf8_encoded_object(object)
        object
      end
    end

    if "".respond_to?(:lines)
      def string_to_lines(string)
        string.lines.to_a
      end
    else
      def string_to_lines(string)
        ary = []
        string.each_line{|l| ary << l}
        ary
      end
    end
  end
end
