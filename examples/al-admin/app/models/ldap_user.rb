require 'active_ldap/user_password'

class LdapUser < ActiveLdap::Base
  ldap_mapping :prefix => "ou=Users",
               :classes => ["person"],
               :dn_attribute => "cn"

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
    establish_connection(:password => password)
    true
  rescue ActiveLdap::AuthenticationError,
      ActiveLdap::LdapError::UnwillingToPerform
    false
  end

  private
  def encrypt_password
    return if password.blank?
    if /\A\{([A-Z][A-Z\d]+)\}/ =~ userPassword.to_s
      hash_type = $1.downcase
      self.user_password = ActiveLdap::UserPassword.send(hash_type, password)
    else
      self.user_password = password
    end
  end

  def password_required?
    !password.blank?
  end
end
