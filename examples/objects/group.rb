class Group < ActiveLdap::Base
  ldap_mapping :dn_attribute => "cn",
               :classes => ['posixGroup'],
               :prefix => 'ou=Groups'
  # Inspired by ActiveRecord, this tells ActiveLDAP that the
  # LDAP entry has a attribute which contains one or more of
  # some class |:class_name| where the attributes name is
  # |:local_key|. This means that it will call
  # :class_name.new(value_of(:local_key)) to create the objects.
  has_many :members, :class_name => "User", :wrap => "memberUid"
  has_many :primary_members, :class_name => 'User',
           :foreign_key => 'gidNumber',
           :primary_key => 'gidNumber'
end # Group
