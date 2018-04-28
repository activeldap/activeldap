module ActiveLdap
  module AttributeMethods
    module Write
      extend ActiveSupport::Concern

      included do
        attribute_method_suffix '='
      end

      private
      def attribute=(attr, *args)
        return set_attribute(attr, args.first)
      end

      # set_attribute
      #
      # Set the value of the attribute called by method_missing?
      def set_attribute(name, value)
        real_name = to_real_attribute_name(name)
        _dn_attribute = nil
        valid_dn_attribute = true
        begin
          _dn_attribute = dn_attribute
        rescue DistinguishedNameInvalid
          valid_dn_attribute = false
        end
        if valid_dn_attribute and real_name == _dn_attribute
          real_name, value = register_new_dn_attribute(real_name, value)
        end
        raise UnknownAttribute.new(name) if real_name.nil?

        @data[real_name] = value
        @simplified_data = nil
      end

    end
  end
end
