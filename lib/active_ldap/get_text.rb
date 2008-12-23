if Object.const_defined?(:GetText)
  begin
    require 'active_record/version'
    active_record_version = [ActiveRecord::VERSION::MAJOR,
                             ActiveRecord::VERSION::MINOR,
                             ActiveRecord::VERSION::TINY]
    if (active_record_version <=> [2, 2, 0]) < 0
      require "gettext/active_record"
    end
    ActiveLdap.const_set("GetText", GetText)
  end
else
  require 'active_ldap/get_text_fallback'
end

require 'active_ldap/get_text_support'
