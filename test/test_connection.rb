require 'al-test-utils'

class ConnectionTest < Test::Unit::TestCase
  include AlTestUtils::Config

  def setup
    super
  end

  def teardown
    ActiveLdap::Base.clear_active_connections!
    super
  end

  def test_can_reconnect?
    assert(!ActiveLdap::Base.connected?)

    config = establish_connection_config.merge({:retry_limit => 10})
    ActiveLdap::Base.establish_connection(config)
    connection = ActiveLdap::Base.connection
    connection.instance_variable_set("@reconnect_attempts", 10)
    assert(!connection.can_reconnect?)

    config = establish_connection_config.merge({:retry_limit => 10})
    ActiveLdap::Base.establish_connection(config)
    connection = ActiveLdap::Base.connection
    connection.instance_variable_set("@reconnect_attempts", 9)
    assert(!connection.can_reconnect?)

    config = establish_connection_config.merge({:retry_limit => 10})
    ActiveLdap::Base.establish_connection(config)
    connection = ActiveLdap::Base.connection
    connection.instance_variable_set("@reconnect_attempts", 8)
    assert(connection.can_reconnect?)

    config = establish_connection_config.merge({:retry_limit => -1})
    ActiveLdap::Base.establish_connection(config)
    connection = ActiveLdap::Base.connection
    connection.instance_variable_set("@reconnect_attempts", -10)
    assert(connection.can_reconnect?)
  end
end
