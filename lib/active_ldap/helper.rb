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
  end
end
