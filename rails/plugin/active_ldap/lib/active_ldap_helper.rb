module ActiveLdapHelper
  def ldap_attribute_name_gettext(attribute)
    ActiveLdap::Base.human_attribute_name(attribute)
  end
  alias_method(:la_, :ldap_attribute_name_gettext)

  def ldap_attribute_description_gettext(attribute)
    ActiveLdap::Base.human_attribute_description(attribute)
  end
  alias_method(:lad_, :ldap_attribute_description_gettext)

  def ldap_object_class_name_gettext(object_class)
    ActiveLdap::Base.human_object_class_name(object_class)
  end
  alias_method(:loc_, :ldap_object_class_name_gettext)

  def ldap_object_class_description_gettext(object_class)
    ActiveLdap::Base.human_object_class_description(object_class)
  end
  alias_method(:locd_, :ldap_object_class_description_gettext)
end
