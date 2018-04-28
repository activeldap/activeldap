module ActiveLdap
  module AttributeMethods
    module BeforeTypeCast
      extend ActiveSupport::Concern

      included do
        attribute_method_suffix '_before_type_cast'
      end

      private
      def attribute_before_type_cast(attr)
        get_attribute_before_type_cast(attr)[1]
      end

      def get_attribute_before_type_cast(name, force_array=false)
        name = to_real_attribute_name(name)

        value = @data[name]
        value = [] if value.nil?
        [name, array_of(value, force_array)]
      end
    end
  end
end
