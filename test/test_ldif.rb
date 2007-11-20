require 'al-test-utils'

class TestLDIF < Test::Unit::TestCase
  include AlTestUtils

  def setup
  end

  def teardown
  end

  priority :must
  def test_entries
    ldif_source = <<-EOL
version: 1
dn: cn=Barbara Jensen, ou=Product Development, dc=airius, dc=com
objectclass: top
objectclass: person
objectclass: organizationalPerson
cn: Barbara Jensen
cn: Barbara J Jensen
cn: Babs Jensen
sn: Jensen
uid: bjensen
telephonenumber: +1 408 555 1212
description: A big sailing fan.

dn: cn=Bjorn Jensen, ou=Accounting, dc=airius, dc=com
objectclass: top
objectclass: person
objectclass: organizationalPerson
cn: Bjorn Jensen
sn: Jensen
telephonenumber: +1 408 555 1212
EOL

    entry1 = {
      "dn" => "cn=Barbara Jensen,ou=Product Development,dc=airius,dc=com",
      "objectclass" => ["top", "person", "organizationalPerson"],
      "cn" => ["Barbara Jensen", "Barbara J Jensen", "Babs Jensen"],
      "sn" => ["Jensen"],
      "uid" => ["bjensen"],
      "telephonenumber" => ["+1 408 555 1212"],
      "description" => ["A big sailing fan."],
    }
    entry2 = {
      "dn" => "cn=Bjorn Jensen,ou=Accounting,dc=airius,dc=com",
      "objectclass" => ["top", "person", "organizationalPerson"],
      "cn" => ["Bjorn Jensen"],
      "sn" => ["Jensen"],
      "telephonenumber" => ["+1 408 555 1212"],
    }
    assert_ldif(1, [entry1, entry2], ldif_source)
  end

  def test_an_entry
    ldif_source = <<-EOL
version: 1
dn: cn=Barbara Jensen, ou=Product Development, dc=airius, dc=com
objectclass: top
objectclass: person
objectclass: organizationalPerson
cn: Barbara Jensen
cn: Barbara J Jensen
cn: Babs Jensen
sn: Jensen
uid: bjensen
telephonenumber: +1 408 555 1212
description: A big sailing fan.
EOL
    entry = {
      "dn" => "cn=Barbara Jensen,ou=Product Development,dc=airius,dc=com",
      "objectclass" => ["top", "person", "organizationalPerson"],
      "cn" => ["Barbara Jensen", "Barbara J Jensen", "Babs Jensen"],
      "sn" => ["Jensen"],
      "uid" => ["bjensen"],
      "telephonenumber" => ["+1 408 555 1212"],
      "description" => ["A big sailing fan."],
    }
    assert_ldif(1, [entry], ldif_source)
  end

  def test_dn_spec
    assert_invalid_ldif("'dn:' is missing", "version: 1\n")
    assert_invalid_ldif("DN is missing", "version: 1\ndn:")
    assert_invalid_ldif("DN is missing", "version: 1\ndn:\n")
    assert_invalid_ldif("DN is missing", "version: 1\ndn: \n")

    dn = "cn=Barbara Jensen,ou=Product Development,dc=example,dc=com"
    cn = "Barbara Jensen"
    assert_valid_dn(dn,
                    "version: 1\ndn: #{dn}\ncn:#{cn}\n")

    encoded_dn = Base64.encode64(dn).gsub(/\n/, "\n ")
    encoded_cn = Base64.encode64(cn).gsub(/\n/, "\n ")
    assert_valid_dn(dn, "version: 1\ndn:: #{encoded_dn}\ncn::#{encoded_cn}\n")
  end

  def test_version_number
    assert_valid_version(1, "version: 1\ndn: dc=com\ndc: com")
    assert_valid_version(1, "version: 1\r\ndn: dc=com\ndc: com\n")
    assert_valid_version(1, "version: 1\r\n\n\r\n\ndn: dc=com\ndc: com\n")

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
  def assert_ldif(version, entries, ldif_source)
    ldif = ActiveLdap::Ldif.parse(ldif_source)
    assert_equal(version, ldif.version)
    assert_equal(entries,
                 ldif.entries.collect {|entry| entry.to_hash})
  end

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
