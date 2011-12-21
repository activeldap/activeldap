module ActiveLdap
  module AttributeMethods
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods

    included do
      attribute_method_suffix '_before_type_cast' , '', '?', '='
    end

    protected

    def attribute_before_type_cast(attr)
      get_attribute_before_type_cast(attr)[1]
    end

    def attribute?(attr)
      return get_attribute_as_query(attr)
    end

    def attribute(attr, *args)
      return get_attribute(attr, args.first)
    end

    def attribute=(attr, *args)
      return set_attribute(attr, args.first)
    end

    # ovveriding ActiveModel::AttributeMethods
    def attribute_method?(method_name)
      have_attribute?(method_name, ['objectClass'])
    end
  end
end
