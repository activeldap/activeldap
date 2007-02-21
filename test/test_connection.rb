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
  def test_bind_format_warning
    with_mock_logger do |logger|
      connector = Class.new(ActiveLdap::Base)
      assert(!connector.connected?)
      assert_raises(ActiveLdap::AuthenticationError) do
        connector.establish_connection(:bind_format => "uid=%s,dc=test",
                                       :allow_anonymous => false)
      end
      assert_equal([":bind_format is deprecated. Use :bind_dn instead."],
                   logger.messages(:warn))
    end
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
