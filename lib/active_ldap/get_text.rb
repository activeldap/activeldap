if Object.const_defined?(:FastGettext)
  ActiveLdap.const_set("GetText", FastGettext)
end

unless ActiveLdap.const_defined?(:GetText)
  require 'active_ldap/get_text_fallback'
end

require 'active_ldap/get_text_support'
