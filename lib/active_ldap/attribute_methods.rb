module ActiveLdap
  module AttributeMethods
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods

    protected

    # ovveriding ActiveModel::AttributeMethods
    def attribute_method?(method_name)
      have_attribute?(method_name, ['objectClass'])
    end
  end
end
