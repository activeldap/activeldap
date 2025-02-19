require 'al-test-utils'

class TestMultiConfiguration < Test::Unit::TestCase
  include AlTestUtils

  def setup
    super
    @original_configs = ActiveLdap::Base.configurations.dup
  end

  def teardown
    ActiveLdap::Base.clear_active_connections!
    ActiveLdap::Base.configurations = @original_configs
    super
  end

  def test_configuration_with_no_or_primary_key
    assert_nothing_raised do
      ActiveLdap::Base.setup_connection
    end
    ActiveLdap::Base.configurations[LDAP_ENV] = {
      "primary" => @original_configs[LDAP_ENV]
    }
    assert_nothing_raised do
      ActiveLdap::Base.setup_connection
    end
  end

  def test_configuration_with_special_key
    ActiveLdap::Base.configurations[LDAP_ENV] = {
      "special" => @original_configs[LDAP_ENV]
    }
    assert_nothing_raised do
      connect(ActiveLdap::Base, {name: :special})
    end
  end

  def test_configuration_with_special_key_as_string
    ActiveLdap::Base.configurations[LDAP_ENV] = {
      "special" => @original_configs[LDAP_ENV]
    }
    assert_nothing_raised do
      connect(ActiveLdap::Base, {name: "special"})
    end
    assert_nothing_raised do
      connect(ActiveLdap::Base, {"name" => "special"})
    end
  end

  def test_configuration_with_special_key_without_ldap_env
    begin
      ActiveLdap::Base.configurations = {
        "special" => @original_configs[LDAP_ENV]
      }

      # temporarily undefine LDAP_ENV
      ldap_env = LDAP_ENV
      Object.__send__(:remove_const, :LDAP_ENV)

      assert_nothing_raised do
        connect(ActiveLdap::Base, {name: :special})
      end
    ensure
      Object.const_set(:LDAP_ENV, ldap_env)
    end
  end

  def test_configuration_with_special_key_and_missing_config
    exception = nil
    assert_raise(ActiveLdap::ConnectionError) do
      begin
        connect(ActiveLdap::Base, {name: :special})
      rescue Exception
        exception = $!
        raise
      end
    end
    expected_message = "special connection is not configured"
    assert_equal(expected_message, exception.message)
  end

  def test_configuration_per_class
    make_ou("Primary")
    make_ou("Sub")
    primary_class = ou_class("ou=Primary")
    sub_class = ou_class("ou=Sub")

    configuration = current_configuration.symbolize_keys
    configuration[:scope] = :base
    current_base = configuration[:base]
    primary_configuration = configuration.dup
    primary_base = "ou=Primary,#{current_base}"
    primary_configuration[:base] = primary_base
    sub_configuration = configuration.dup
    sub_base = "ou=Sub,#{current_base}"
    sub_configuration[:base] = sub_base

    ActiveLdap::Base.configurations[LDAP_ENV] = {
      "primary" => primary_configuration,
      "sub" => sub_configuration
    }
    assert_nothing_raised do
      connect(primary_class)
      connect(sub_class, {name: :sub})
    end
  end

  private
  def connect(klass, config = nil)
    klass.setup_connection(config)
    klass.connection.connect
  end
end