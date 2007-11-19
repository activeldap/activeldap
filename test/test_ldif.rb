require 'al-test-utils'

class TestLDIF < Test::Unit::TestCase
  include AlTestUtils

  def setup
  end

  def teardown
  end

  priority :must
  def test_dn_spec
    assert_invalid_ldif("'dn:' is missing", "version: 1\n")

    assert_valid_dn("cn=Barbara Jensen,ou=Product Development,dc=example,dc=com",
                    "version: 1\n" +
                    "dn: cn=Barbara Jensen, ou=Product Development, " +
                    "dc=example, dc=com")
  end

  def test_version_number
    assert_valid_version(1, "version: 1\ndn:")
    assert_valid_version(1, "version: 1\r\ndn:")
    assert_valid_version(1, "version: 1\r\n\n\r\n\ndn:")

    assert_invalid_ldif("unsupported version: 0", "version: 0")
    assert_invalid_ldif("unsupported version: 2", "version: 2")
  end

  def test_version_spec
    assert_invalid_ldif("version spec is missing", "")
    assert_invalid_ldif("version spec is missing", "version:")
    assert_invalid_ldif("version spec is missing", "version: ")
    assert_invalid_ldif("version spec is missing", "version: XXX")
  end

  priority :normal

  private
  def assert_valid_dn(dn, ldif_source)
    ldif = ActiveLdap::Ldif.parse(ldif_source)
    assert_equal([dn], ldif.entries.collect {|entry| entry.dn})
  end

  def assert_valid_version(version, ldif_source)
    ldif = ActiveLdap::Ldif.parse(ldif_source)
    assert_equal(version, ldif.version)
  end

  def assert_invalid_ldif(reason, ldif)
    exception = assert_raise(ActiveLdap::LdifInvalid) do
      ActiveLdap::Ldif.parse(ldif)
    end
    assert_equal(ldif, exception.ldif)
    assert_equal(_(reason), exception.reason)
  end
end
