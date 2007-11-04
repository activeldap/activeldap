require 'al-test-utils'

class TestLDIF < Test::Unit::TestCase
  include AlTestUtils

  def setup
  end

  def teardown
  end

  priority :must
  def test_version_number
    assert_invalid_ldif("unsupported version: 0", "version: 0")
    assert_invalid_ldif("unsupported version: 0", "version: 0")
  end

  def test_version_spec
    assert_invalid_ldif("version spec is missing", "")
    assert_invalid_ldif("version spec is missing", "version:")
    assert_invalid_ldif("version spec is missing", "version: ")
    assert_invalid_ldif("version spec is missing", "version: XXX")
  end

  priority :normal

  private
  def assert_invalid_ldif(reason, ldif)
    exception = assert_raise(ActiveLdap::LdifInvalid) do
      ActiveLdap::Ldif.parse(ldif)
    end
    assert_equal(ldif, exception.ldif)
    assert_equal(_(reason), exception.reason)
  end
end
