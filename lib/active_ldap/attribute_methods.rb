module ActiveLdap
  module AttributeMethods
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods

    def methods(singleton_methods = true)
      target_names = entry_attribute.all_names
      target_names -= ['objectClass', 'objectClass'.underscore]
      super + target_names.uniq.collect do |attr|
        self.class.attribute_method_matchers.collect do |matcher|
          :"#{matcher.prefix}#{attr}#{matcher.suffix}"
        end
      end.flatten
    end

    private
    # overiding ActiveModel::AttributeMethods
    def attribute_method?(method_name)
      have_attribute?(method_name, ['objectClass'])
    end
  end
end
