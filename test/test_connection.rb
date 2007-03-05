require 'al-test-utils'

class TestConnection < Test::Unit::TestCase
  include AlTestUtils::Config
  include AlTestUtils::MockLogger

  def setup
    super
  end

  def teardown
    ActiveLdap::Base.clear_active_connections!
    super
  end

  priority :must
  def test_bind_format_check
    connector = Class.new(ActiveLdap::Base)
    assert(!connector.connected?)
    exception = nil
    assert_raises(ArgumentError) do
      begin
        connector.establish_connection(:bind_format => "uid=%s,dc=test",
                                       :allow_anonymous => false)
      rescue Exception
        exception = $!
        raise
      end
    end
    assert_equal("Unknown key(s): bind_format", exception.message)
  end

  priority :normal
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
