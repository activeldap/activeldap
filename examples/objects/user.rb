class User < ActiveLdap::Base
  ldap_mapping :dn_attribute => 'uid', :prefix => 'ou=People',
               :classes => ['person', 'posixAccount']
  belongs_to :primary_group, :class => "Group",
             :foreign_key => "gidNumber", :primary_key => "gidNumber"
  belongs_to :groups, :many => 'memberUid'
end
