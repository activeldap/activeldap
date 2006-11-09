class User < ActiveLdap::Base
  ldap_mapping :dnattr => 'uid', :prefix => 'ou=People',
               :classes => ['person', 'posixAccount']
  belongs_to :groups, :many => 'memberUid'
end
