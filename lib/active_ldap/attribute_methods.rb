module ActiveLdap
  module AttributeMethods
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods

    def methods(singleton_methods = true)
      target_names = entry_attribute.all_names
      target_names -= ['objectClass', 'objectClass'.underscore]
      super + target_names.uniq.collect do |attr|
        method_patterns = 
          if self.class.respond_to?(:attribute_method_patterns)
            # Support for ActiveModel >= 7.1.0
            self.class.attribute_method_patterns
          else
            # Support for ActiveModel < 7.1.0
            self.class.attribute_method_matchers
          end
        
        method_patterns.collect do |pattern|
          pattern.method_name(attr).to_sym
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
