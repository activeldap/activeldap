require 'al-test-utils'

class TestConnection < Test::Unit::TestCase
  include AlTestUtils::Config
  include AlTestUtils::MockLogger
  include AlTestUtils::Omittable

  def setup
    super
  end

  def teardown
    ActiveLdap::Base.clear_active_connections!
    super
  end

  priority :must
  def test_retry_limit_0_with_existent_host
    config = current_configuration.merge("retry_limit" => 0)
    ActiveLdap::Base.setup_connection(config)
    assert_nothing_raised do
      ActiveLdap::Base.find(:all)
    end
  end

  def test_retry_limit_0_with_nonexistent_host_with_timeout
    omit_if_jruby("JNI adapter returns connection error immediately. " +
                  "So timeout isn't invoked.")
    config = current_configuration.merge("host" => "192.168.29.29",
                                         "retry_limit" => 0,
                                         "timeout" => 1)
    ActiveLdap::Base.setup_connection(config)
    assert_raise(ActiveLdap::TimeoutError) do
      ActiveLdap::Base.find(:first)
    end
  end

  def test_bind_format_check
    connector = Class.new(ActiveLdap::Base)
    assert(!connector.connected?)
    exception = nil
    assert_raises(ArgumentError) do
      begin
        connector.setup_connection(:adapter => adapter,
                                   :bind_format => "uid=%s,dc=test",
                                   :allow_anonymous => false)
        connector.connection.connect
      rescue Exception
        exception = $!
        raise
      end
    end
    expected_message = "Unknown key: :bind_format. Valid keys are: "
    valid_keys = ActiveLdap::Adapter::Base::VALID_ADAPTER_CONFIGURATION_KEYS
    expected_message << valid_keys.collect(&:inspect).join(", ")
    assert_equal(expected_message, exception.message)
  end

  def test_can_reconnect?
    assert(!ActiveLdap::Base.connected?)

    config = current_configuration.merge("retry_limit" => 10)
    ActiveLdap::Base.setup_connection(config)
    connection = ActiveLdap::Base.connection
    assert(!connection.send(:can_reconnect?, :reconnect_attempts => 11))

    config = current_configuration.merge("retry_limit" => 10)
    ActiveLdap::Base.setup_connection(config)
    connection = ActiveLdap::Base.connection
    assert(connection.send(:can_reconnect?, :reconnect_attempts => 10))

    config = current_configuration.merge("retry_limit" => -1)
    ActiveLdap::Base.setup_connection(config)
    connection = ActiveLdap::Base.connection
    assert(connection.send(:can_reconnect?, :reconnect_attempts => -10))
  end

  priority :low
  def test_retry_limit_0_with_nonexistent_host
    omit("this test will take a long time...")
    config = current_configuration.merge("host" => "192.168.29.29",
                                         "retry_limit" => 0)
    ActiveLdap::Base.setup_connection(config)
    assert_raise(ActiveLdap::ConnectionError) do
      ActiveLdap::Base.find(:first)
    end
  end
end
