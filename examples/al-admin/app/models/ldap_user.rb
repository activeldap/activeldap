require 'active_ldap/user_password'

class LdapUser < ActiveLdap::Base
  ldap_mapping :prefix => "ou=Users",
               :classes => ["person"],
               :dn_attribute => "cn"

  N_("LdapUser|Password")
  N_("LdapUser|Password confirmation")
  attr_accessor :password

  validates_presence_of :password, :password_confirmation,
                        :if => :password_required?
  validates_length_of :password, :within => 4..40,
                      :if => :password_required?
  validates_confirmation_of :password, :if => :password_required?
  before_save :encrypt_password

  class << self
    def authenticate(dn, password)
      user = find(dn)
      user.authenticated?(password) ? user : nil
    rescue ActiveLdap::EntryNotFound
      nil
    end
  end

  def authenticated?(password)
    bind(password)
    true
  rescue ActiveLdap::AuthenticationError,
      ActiveLdap::LdapError::UnwillingToPerform
    false
  end

  private
  def encrypt_password
    return if password.blank?
    hash_type = "ssha"
    if /\A\{([A-Z][A-Z\d]+)\}/ =~ userPassword.to_s
      hash_type = $1.downcase
    end
    self.user_password = ActiveLdap::UserPassword.send(hash_type, password)
  end

  def password_required?
    user_password.blank? or !password.blank?
  end
end
