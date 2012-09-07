module ActiveLdap
  class Entry < ActiveLdap::Base
    ldap_mapping :prefix => "",
                 :classes => ["top"],
                 :scope => :sub
    self.dn_attribute = nil
  end
end
