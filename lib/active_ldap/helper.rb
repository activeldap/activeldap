module ActiveLdap
  module Helper
    def ldap_attribute_name_gettext(attribute)
      Base.human_attribute_name(attribute)
    end
    alias_method(:la_, :ldap_attribute_name_gettext)

    def ldap_attribute_description_gettext(attribute)
      Base.human_attribute_description(attribute)
    end
    alias_method(:lad_, :ldap_attribute_description_gettext)

    def ldap_object_class_name_gettext(object_class)
      Base.human_object_class_name(object_class)
    end
    alias_method(:loc_, :ldap_object_class_name_gettext)

    def ldap_object_class_description_gettext(object_class)
      Base.human_object_class_description(object_class)
    end
    alias_method(:locd_, :ldap_object_class_description_gettext)

    def ldap_syntax_name_gettext(syntax)
      Base.human_syntax_name(syntax)
    end
    alias_method(:ls_, :ldap_syntax_name_gettext)

    def ldap_syntax_description_gettext(syntax)
      Base.human_syntax_description(syntax)
    end
    alias_method(:lsd_, :ldap_syntax_description_gettext)

    def ldap_field(type, object_name, method, options={})
      case type
      when "radio_button", "check_box", "text_area"
        form_method = type
      else
        form_method = "#{type}_field"
      end

      object = options[:object]
      if object.nil?
        normalized_object_name = object_name.to_s.sub(/\[\](\])?$/, "\\1")
        object = instance_variable_get("@#{normalized_object_name}")
      end
      values = object.nil? ? nil : object[method, true]
      values = [nil] if values.blank?
      required_ldap_options = options.delete(:ldap_options) || []
      required_ldap_options.each do |required_ldap_option|
        found = false
        values.each do |value|
          next unless value.is_a?(Hash)
          if Hash.to_a[0].to_s == required_ldap_option.to_s
            found = true
            break
          end
        end
        values << {required_ldap_option => ""} unless found
      end

      fields = []
      collect_values = Proc.new do |value, ldap_options|
        case value
        when Hash
          value.each do |k, v|
            collect_values.call(v, ldap_options + [k])
          end
        when Array
          value.each do |v|
            collect_values.call(v, ldap_options)
          end
        else
          id = "#{object_name}_#{method}"
          name = "#{object_name}[#{method}][]"
          ldap_options.collect.each do |ldap_option|
            id << "_#{ldap_option}"
            name << "[#{ldap_option}][]"
          end
          ldap_value_options = {:id => id, :name => name, :value => value}
          field = send(form_method, object_name, method,
                       ldap_value_options.merge(options))
           if block_given?
             field = yield(field, {:options => ldap_options, :value => value})
           end
          fields << field unless field.blank?
        end
      end
      collect_values.call(values, [])
      fields.join("\n")
    end
  end
end
