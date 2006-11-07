require 'al-test-utils'

class ConnectionTest < Test::Unit::TestCase
  include AlTestUtils::Config

  def setup
    super
  end

  def teardown
    ActiveLDAP::Base.clear_active_connections!
    super
  end

  def test_can_reconnect?
    assert(!ActiveLDAP::Base.connected?)

    config = connect_config.merge({:retry_limit => 10})
    ActiveLDAP::Base.establish_connection(config)
    connection = ActiveLDAP::Base.connection
    connection.instance_variable_set("@reconnect_attempts", 10)
    assert(!connection.can_reconnect?)

    config = connect_config.merge({:retry_limit => 10})
    ActiveLDAP::Base.establish_connection(config)
    connection = ActiveLDAP::Base.connection
    connection.instance_variable_set("@reconnect_attempts", 9)
    assert(!connection.can_reconnect?)

    config = connect_config.merge({:retry_limit => 10})
    ActiveLDAP::Base.establish_connection(config)
    connection = ActiveLDAP::Base.connection
    connection.instance_variable_set("@reconnect_attempts", 8)
    assert(connection.can_reconnect?)

    config = connect_config.merge({:retry_limit => -1})
    ActiveLDAP::Base.establish_connection(config)
    connection = ActiveLDAP::Base.connection
    connection.instance_variable_set("@reconnect_attempts", -10)
    assert(connection.can_reconnect?)
  end
end
