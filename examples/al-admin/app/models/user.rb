require 'digest/sha1'

class User < ActiveRecord::Base
  validates_presence_of     :login
  validates_presence_of     :dn
  validates_uniqueness_of   :login, :dn, :case_sensitive => false
  before_validation :generate_salt, :find_dn

  class << self
    def authenticate(login, password)
      u = find_by_login(login) # need to get the salt
      if u.nil?
        u = new
        u.login = login
        u = nil unless u.save
      end
      u && u.authenticated?(password) ? u : nil
    end

    def encrypt(password, salt)
      Digest::SHA1.hexdigest("--#{salt}--#{password}--")
    end
  end

  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    return false if ldap_user.nil?
    ldap_user.authenticated?(password)
  end

  def ldap_user
    @ldap_user ||= LdapUser.find(dn)
  rescue ActiveLdap::EntryNotFound
  end

  def connected?
    ldap_user.connected?
  end

  def remember_token?
    begin
      remember_token_expires_at and
        Time.now.utc < remember_token_expires_at and
        connected?
    rescue ActiveLdap::EntryNotFound
      false
    end
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token = encrypt("#{dn}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
    LdapUser.remove_connection(dn) if dn
    @ldap_user = nil
  end

  private
  def generate_salt
    return unless new_record?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--")
  end

  def find_dn
    if login.blank?
      self.dn = nil
    else
      begin
        ldap_user = LdapUser.find(login)
        self.dn = ldap_user.dn
      rescue ActiveLdap::EntryNotFound
        self.dn = nil
      end
    end
  end
end
