require 'al-test-utils'

class TestConfiguration < Test::Unit::TestCase
  priority :must

  priority :normal
  def test_prepare_configuration_with_silent_uri
    configuration = {
      :base => "dc=example,dc=com",
      :password => "secret",
      :uri => "ldap://example.com/dc=ignore,dc=me"
    }
    prepared_configuration =
      ActiveLdap::Base.prepare_configuration(configuration)
    assert_equal({
                   :host => "example.com",
                   :port => 389,
                   :base => "dc=example,dc=com",
                   :password => "secret",
                 },
                 prepared_configuration)
  end

  def test_prepare_configuration_with_detailed_uri
    bind_dn = "cn=admin,dc=example,dc=com"
    configuration = {
      :host => "example.net",
      :uri => "ldaps://example.com/dc=example,dc=com??sub??!bindname=#{CGI.escape(bind_dn)}"
    }
    prepared_configuration =
      ActiveLdap::Base.prepare_configuration(configuration)
    assert_equal({
                   :host => "example.net",
                   :port => 636,
                   :method => :ssl,
                   :base => "dc=example,dc=com",
                   :scope => "sub",
                   :bind_dn => "cn=admin,dc=example,dc=com",
                   :allow_anonymous => false,
                 },
                 prepared_configuration)
  end
end
