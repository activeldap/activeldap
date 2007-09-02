begin
  require "gettext/active_record"
  ActiveLdap.const_set("GetText", GetText)
rescue LoadError
  require 'active_ldap/get_text_fallback'
end

require 'active_ldap/get_text_support'
