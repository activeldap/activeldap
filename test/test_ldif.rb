require 'al-test-utils'

class TestLDIF < Test::Unit::TestCase
  include AlTestUtils

  def setup
  end

  def teardown
  end

  priority :must
  def test_an_entry_with_base64_encoded_value
    ldif_source = <<-EOL
version: 1
dn: cn=Gern Jensen, ou=Product Testing, dc=airius, dc=com
objectclass: top
objectclass: person
objectclass: organizationalPerson
cn: Gern Jensen
cn: Gern O Jensen
sn: Jensen
uid: gernj
telephonenumber: +1 408 555 1212
description:: V2hhdCBhIGNhcmVmdWwgcmVhZGVyIHlvdSBhcmUhICBUaGlzIHZhbHVl
 IGlzIGJhc2UtNjQtZW5jb2RlZCBiZWNhdXNlIGl0IGhhcyBhIGNvbnRyb2wgY2hhcmFjdG
 VyIGluIGl0IChhIENSKS4NICBCeSB0aGUgd2F5LCB5b3Ugc2hvdWxkIHJlYWxseSBnZXQg
 b3V0IG1vcmUu
EOL

    entry = {
      "dn" => "cn=Gern Jensen,ou=Product Testing,dc=airius,dc=com",
      "objectclass" => ["top", "person", "organizationalPerson"],
      "cn" => ["Gern Jensen", "Gern O Jensen"],
      "sn" => ["Jensen"],
      "uid" => ["gernj"],
      "telephonenumber" => ["+1 408 555 1212"],
      "description" => ["What a careful reader you are!  " +
                        "This value is base-64-encoded because it has a " +
                        "control character in it (a CR).\r  By the way, " +
                        "you should really get out more."],
    }
    assert_ldif(1, [entry], ldif_source)
  end

  def test_an_entry_with_folded_attribute_value
    ldif_source = <<-EOL
version: 1
dn:cn=Barbara Jensen, ou=Product Development, dc=airius, dc=com
objectclass:top
objectclass:person
objectclass:organizationalPerson
cn:Barbara Jensen
cn:Barbara J Jensen
cn:Babs Jensen
sn:Jensen
uid:bjensen
telephonenumber:+1 408 555 1212
description:Babs is a big sailing fan, and travels extensively in sea
 rch of perfect sailing conditions.
title:Product Manager, Rod and Reel Division
EOL

    entry = {
      "dn" => "cn=Barbara Jensen,ou=Product Development,dc=airius,dc=com",
      "objectclass" => ["top", "person", "organizationalPerson"],
      "cn" => ["Barbara Jensen", "Barbara J Jensen", "Babs Jensen"],
      "sn" => ["Jensen"],
      "uid" => ["bjensen"],
      "telephonenumber" => ["+1 408 555 1212"],
      "description" => ["Babs is a big sailing fan, and travels extensively " +
                        "in search of perfect sailing conditions."],
      "title" => ["Product Manager, Rod and Reel Division"],
    }
    assert_ldif(1, [entry], ldif_source)
  end

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

  def test_comment
    ldif_source = <<-EOL
version: 1
dn: cn=Barbara Jensen, ou=Product Development, dc=airius, dc=com
objectclass: top
# objectclass: person
#objectcl
 ass: organizationalPerson
EOL

    entry = {
      "dn" => "cn=Barbara Jensen,ou=Product Development,dc=airius,dc=com",
      "objectclass" => ["top"],
    }
    assert_ldif(1, [entry], ldif_source)
  end

  def test_dn_spec
    assert_invalid_ldif("'dn:' is missing",
                        "version: 1\n", 2, 1, "version: 1\n|@|")
    assert_invalid_ldif("DN is missing",
                        "version: 1\ndn:", 2, 4, "dn:|@|")
    assert_invalid_ldif("DN is missing",
                        "version: 1\ndn:\n", 3, 1, "dn:\n|@|")
    assert_invalid_ldif("DN is missing",
                        "version: 1\ndn: \n", 3, 1, "dn: \n|@|")

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

    assert_invalid_ldif("unsupported version: 0",
                        "version: 0", 1, 11, "version: 0|@|")
    assert_invalid_ldif("unsupported version: 2",
                        "version: 2", 1, 11, "version: 2|@|")
  end

  def test_version_spec
    assert_invalid_ldif("version spec is missing",
                        "", 1, 1, "|@|")
    assert_invalid_ldif("version spec is missing",
                        "VERSION: 1", 1, 1, "|@|VERSION: 1")
    assert_invalid_ldif("version number is missing",
                        "version:", 1, 9, "version:|@|")
    assert_invalid_ldif("version number is missing",
                        "version: ", 1, 10, "version: |@|")
    assert_invalid_ldif("version number is missing",
                        "version: XXX", 1, 10, "version: |@|XXX")
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

  def assert_invalid_ldif(reason, ldif, line, column, nearest)
    exception = assert_raise(ActiveLdap::LdifInvalid) do
      ActiveLdap::Ldif.parse(ldif)
    end
    assert_equal([_(reason), line, column, nearest, ldif],
                 [exception.reason, exception.line, exception.column,
                  exception.nearest, exception.ldif])
  end
end
