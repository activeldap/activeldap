class User < ActiveLDAP::Base
#  ldap_mapping :dnattr => 'uid', :prefix => 'ou=People', :classes => ['person', 'posixAccount']
  ldap_mapping :dnattr => 'uid', :prefix => 'ou=People', :classes => ['posixAccount']
  belongs_to :groups, :class_name => 'Group', :foreign_key => 'memberUid'
end
