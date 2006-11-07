require 'al-test-utils'

class BindTest < Test::Unit::TestCase
  include AlTestUtils::Config

  def setup
    super
  end

  def teardown
    ActiveLDAP::Base.clear_active_connections!
    super
  end

  def test_anonymous
    assert(!ActiveLDAP::Base.connected?)
    assert_nothing_raised do
      config = connect_config
      config.delete(:user)
      config[:allow_anonymous] = true
      ActiveLDAP::Base.establish_connection(config)
    end
    assert(ActiveLDAP::Base.connected?,
           "Checking is the connection was established.")
  end

  def test_bind
    assert(!ActiveLDAP::Base.connected?)
    config = connect_config
    if config[:user].nil? or config[:bind_format].nil? or config[:password].nil?
      puts "pass this test for no user configuration"
      return
    end
    assert_nothing_raised do
      config[:allow_anonymous] = false
      ActiveLDAP::Base.establish_connection(config)
    end
    assert(ActiveLDAP::Base.connected?,
           "Checking is the connection was established.")
    assert(ActiveLDAP::Base.connection.bound?)
  end

  def test_failed_bind
    assert(!ActiveLDAP::Base.connected?)
    assert_raises(LDAP::InvalidCredentials) do
      config = connect_config
      config.delete(:user)
      config[:allow_anonymous] = false
      ActiveLDAP::Base.establish_connection(config)
    end
    assert(!ActiveLDAP::Base.connection.bound?)
  end
end
