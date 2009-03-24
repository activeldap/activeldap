if Object.const_defined?(:GetText)
  ActiveLdap.const_set("GetText", GetText)
end

unless ActiveLdap.const_defined?(:GetText)
  require 'active_ldap/get_text_fallback'
end

require 'active_ldap/get_text_support'
