require 'al-test-utils'

class TestConfiguration < Test::Unit::TestCase
  priority :must

  priority :normal
  def test_prepare_configuration_with_silent_uri
    configuration = {
      :bind_dn => "cn=admin,dc=example,dc=com",
      :password => "secret",
      :uri => "ldap://example.com/cn=ignore,dc=me"
    }
    prepared_configuration =
      ActiveLdap::Base.prepare_configuration(configuration)
    assert_equal({
                   :host => "example.com",
                   :port => 389,
                   :bind_dn => "cn=admin,dc=example,dc=com",
                   :password => "secret",
                 },
                 prepared_configuration)
  end

  def test_prepare_configuration_with_detailed_uri
    configuration = {
      :host => "example.net",
      :uri => "ldaps://example.com/cn=admin,dc=example,dc=com??sub"
    }
    prepared_configuration =
      ActiveLdap::Base.prepare_configuration(configuration)
    assert_equal({
                   :host => "example.net",
                   :port => 636,
                   :method => :ssl,
                   :bind_dn => "cn=admin,dc=example,dc=com",
                   :scope => "sub",
                 },
                 prepared_configuration)
  end
end
