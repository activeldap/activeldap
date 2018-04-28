#
module ActiveLdap
  module AttributeMethods
    module Query
      extend ActiveSupport::Concern

      included do
        attribute_method_suffix '?'
      end

      private
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

      def attribute?(attr)
        return get_attribute_as_query(attr)
      end
    end
  end
end
