class User < ActiveLdap::Base
  ldap_mapping :dnattr => 'uid', :prefix => 'ou=People',
               :classes => ['person', 'posixAccount']
  belongs_to :primary_group, :class_name => "Group",
             :foreign_key => "gidNumber", :primary_key => "gidNumber"
  belongs_to :groups, :many => 'memberUid'
end
