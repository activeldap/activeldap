class Ou < ActiveLdap::Base
  ldap_mapping :dn_attribute => 'ou', :prefix => '',
               :classes => ['top', 'organizationalUnit']
end
