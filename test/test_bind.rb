require 'al-test-utils'

class TestBind < Test::Unit::TestCase
  include AlTestUtils::Config

  def setup
    super
  end

  def teardown
    ActiveLdap::Base.clear_active_connections!
    super
  end

  def test_anonymous
    assert(!ActiveLdap::Base.connected?)
    assert_nothing_raised do
      config = ActiveLdap::Base.configurations[LDAP_ENV].symbolize_keys
      config = ActiveLdap::Base.prepare_configuration(config)
      config.delete(:bind_dn)
      config[:allow_anonymous] = true
      connect(config)
    end
    assert(ActiveLdap::Base.connected?,
           "Checking is the connection was established.")
  end

  def test_bind
    assert(!ActiveLdap::Base.connected?)
    config = ActiveLdap::Base.configurations[LDAP_ENV].symbolize_keys
    config = ActiveLdap::Base.prepare_configuration(config)
    if config[:bind_dn].nil?
      puts "pass this test for no user configuration"
      return
    end
    assert_nothing_raised do
      config[:allow_anonymous] = false
      connect(config)
    end
    assert(ActiveLdap::Base.connected?,
           "Checking is the connection was established.")
    assert(ActiveLdap::Base.connection.bound?)
  end

  def test_failed_bind
    assert(!ActiveLdap::Base.connected?)
    assert_raises(ActiveLdap::AuthenticationError) do
      config = ActiveLdap::Base.configurations[LDAP_ENV].symbolize_keys
      config = ActiveLdap::Base.prepare_configuration(config)
      config.delete(:bind_dn)
      config[:allow_anonymous] = false
      connect(config)
    end
    assert(!ActiveLdap::Base.connection.bound?)
  end

  private
  def connect(config)
    ActiveLdap::Base.setup_connection(config)
    ActiveLdap::Base.connection.connect
  end
end
