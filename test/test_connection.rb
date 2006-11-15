require 'al-test-utils'

class TestConnection < Test::Unit::TestCase
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

    config = current_configuration.merge("retry_limit" => 10)
    ActiveLdap::Base.establish_connection(config)
    connection = ActiveLdap::Base.connection
    assert(!connection.send(:can_reconnect?, :reconnect_attempts => 10))

    config = current_configuration.merge("retry_limit" => 10)
    ActiveLdap::Base.establish_connection(config)
    connection = ActiveLdap::Base.connection
    assert(!connection.send(:can_reconnect?, :reconnect_attempts => 9))

    config = current_configuration.merge("retry_limit" => 10)
    ActiveLdap::Base.establish_connection(config)
    connection = ActiveLdap::Base.connection
    assert(connection.send(:can_reconnect?, :reconnect_attempts => 8))

    config = current_configuration.merge("retry_limit" => -1)
    ActiveLdap::Base.establish_connection(config)
    connection = ActiveLdap::Base.connection
    assert(connection.send(:can_reconnect?, :reconnect_attempts => -10))
  end
end
