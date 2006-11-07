
class Group < ActiveLDAP::Base
  ldap_mapping :classes => ['posixGroup'], :prefix => 'ou=Group'
  # Inspired by ActiveRecord, this tells ActiveLDAP that the
  # LDAP entry has a attribute which contains one or more of
  # some class |:class_name| where the attributes name is
  # |:local_key|. This means that it will call
  # :class_name.new(value_of(:local_key)) to create the objects.
  has_many :members, :class_name => "User", :local_key => "memberUid"
  belongs_to :primary_members, :class_name => 'User', :foreign_key => 'gidNumber', :local_key => 'gidNumber'
end # Group
