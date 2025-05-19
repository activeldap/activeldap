require 'al-test-utils'

class TestMultiConfiguration < Test::Unit::TestCase
  include AlTestUtils

  def teardown
    ActiveLdap::Base.configurations = read_config
    super
  end

  def test_configuration_with_no_key
    assert do
      connect(ActiveLdap::Base)
    end
  end

  def test_configuration_with_primary_key
    ActiveLdap::Base.configurations[LDAP_ENV] = {
      "primary" => current_configuration
    }
    assert do
      connect(ActiveLdap::Base)
    end
  end

  def test_configuration_with_special_key
    ActiveLdap::Base.configurations[LDAP_ENV] = {
      "special" => current_configuration
    }
    assert do
      connect(ActiveLdap::Base, {name: :special})
    end
  end

  def test_configuration_with_special_key_as_string
    ActiveLdap::Base.configurations[LDAP_ENV] = {
      "special" => current_configuration
    }
    assert do
      connect(ActiveLdap::Base, {name: "special"})
    end
  end

  def test_configuration_with_special_key_without_ldap_env
    begin
      ActiveLdap::Base.configurations = {
        "special" => ActiveLdap::Base.configurations[LDAP_ENV]
      }

      # temporarily undefine LDAP_ENV
      ldap_env = LDAP_ENV
      Object.__send__(:remove_const, :LDAP_ENV)

      assert do
        connect(ActiveLdap::Base, {name: :special})
      end
    ensure
      Object.const_set(:LDAP_ENV, ldap_env)
    end
  end

  def test_configuration_with_special_key_and_missing_config
    message = "special connection is not configured"
    assert_raise(ActiveLdap::ConnectionError.new(message)) do
      connect(ActiveLdap::Base, {name: :special})
    end
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
    assert do
      connect(primary_class) and connect(sub_class, {name: :sub})
    end
  end

  private
  def connect(klass, config = nil)
    klass.setup_connection(config)
    klass.connection.connect
  end
end