require "active_ldap/ldap_controls"

module ActiveLdap
  class SupportedControl
    def initialize(controls)
      @controls = controls
      @paged_results = @controls.include?(LdapControls::PAGED_RESULTS)
    end

    def paged_results?
      @paged_results
    end
  end
end
