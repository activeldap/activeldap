class Entry < ActiveLdap::Base
  ldap_mapping :prefix => "",
               :classes => ["top"],
               :scope => :sub
  self.dn_attribute = nil

  validate :always_fail

  class << self
    def empty?
      search(:scope => :base).empty?
    end
  end

  private
  def always_fail
    errors.add("save", _("disable saving"))
  end
end
