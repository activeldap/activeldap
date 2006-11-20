require 'objects/group'

class User < ActiveLdap::Base
  ldap_mapping :dn_attribute => 'uid', :prefix => 'ou=People',
               :classes => ['person', 'posixAccount']
  belongs_to :primary_group, :class => "Group",
             :foreign_key => "gidNumber", :primary_key => "gidNumber"
  belongs_to :groups, :many => 'memberUid'

  # An example of using the old "return_objects" API with the
  # new ActiveRecord-style API.
  alias groups_mapping groups
  def groups(return_objects=true)
    return self.groups_mapping if return_objects
    attr = 'cn'
    return Group.search(:attribute => 'memberUid',
                        :value => self.send(self.dn_attribute),
                        :attributes => [attr]).map {|x|x[1][attr]}.flatten

  end
end
