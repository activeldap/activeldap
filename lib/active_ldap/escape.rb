module ActiveLdap
  module Escape
    module_function
    def ldap_filter_escape(str)
      str.to_s.gsub(/\*/, "**")
    end

    def ldap_filter_unescape(str)
      str.to_s.gsub(/\*\*/, "*")
    end
  end
end
