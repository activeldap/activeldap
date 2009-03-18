module LdapTestHelper
  def setup_ldap_data
    @ldap_dumped_data = nil
    begin
      @ldap_dumped_data = ActiveLdap::Base.dump(:scope => :sub)
    rescue ActiveLdap::ConnectionError
    end
    ActiveLdap::Base.delete_all(nil, :scope => :sub)
    populate_ldap_data
  end

  def teardown_ldap_data
    if @ldap_dumped_data
      ActiveLdap::Base.setup_connection
      ActiveLdap::Base.delete_all(nil, :scope => :sub)
      ActiveLdap::Base.load(@ldap_dumped_data)
    end
  end

  def populate_ldap_data
    populate_ldap_base
    populate_ldap_ou
  end

  def populate_ldap_base
    ActiveLdap::Populate.ensure_base
  end

  def populate_ldap_ou
    %w(Users Groups).each do |name|
      make_ou(name)
    end
  end

  def make_ou(name)
    ActiveLdap::Populate.ensure_ou(name)
  end
end
