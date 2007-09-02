require 'al-test-utils'

class TestSyntax < Test::Unit::TestCase
  include AlTestUtils
  include ActiveLdap::Helper

  SYNTAXES = \
  [
   "( 1.3.6.1.1.16.1 DESC 'UUID' )",
   "( 1.3.6.1.1.1.0.1 DESC 'RFC2307 Boot Parameter' )",
   "( 1.3.6.1.1.1.0.0 DESC 'RFC2307 NIS Netgroup Triple' )",
   "( 1.3.6.1.4.1.1466.115.121.1.52 DESC 'Telex Number' )",
   "( 1.3.6.1.4.1.1466.115.121.1.50 DESC 'Telephone Number' )",
   "( 1.3.6.1.4.1.1466.115.121.1.49 DESC 'Supported Algorithm' " +
     "X-BINARY-TRANSFER-REQUIRED 'TRUE' X-NOT-HUMAN-READABLE 'TRUE' )",
   "( 1.3.6.1.4.1.1466.115.121.1.45 DESC 'SubtreeSpecification' )",
   "( 1.3.6.1.4.1.1466.115.121.1.44 DESC 'Printable String' )",
   "( 1.3.6.1.4.1.1466.115.121.1.41 DESC 'Postal Address' )",
   "( 1.3.6.1.4.1.1466.115.121.1.40 DESC 'Octet String' )",
   "( 1.3.6.1.4.1.1466.115.121.1.39 DESC 'Other Mailbox' )",
   "( 1.3.6.1.4.1.1466.115.121.1.38 DESC 'OID' )",
   "( 1.3.6.1.4.1.1466.115.121.1.36 DESC 'Numeric String' )",
   "( 1.3.6.1.4.1.1466.115.121.1.34 DESC 'Name And Optional UID' )",
   "( 1.3.6.1.4.1.1466.115.121.1.28 DESC 'JPEG' X-NOT-HUMAN-READABLE 'TRUE' )",
   "( 1.3.6.1.4.1.1466.115.121.1.27 DESC 'Integer' )",
   "( 1.3.6.1.4.1.1466.115.121.1.26 DESC 'IA5 String' )",
   "( 1.3.6.1.4.1.1466.115.121.1.24 DESC 'Generalized Time' )",
   "( 1.3.6.1.4.1.1466.115.121.1.22 DESC 'Facsimile Telephone Number' )",
   "( 1.3.6.1.4.1.1466.115.121.1.15 DESC 'Directory String' )",
   "( 1.3.6.1.4.1.1466.115.121.1.14 DESC 'Delivery Method' )",
   "( 1.2.36.79672281.1.5.0 DESC 'RDN' )",
   "( 1.3.6.1.4.1.1466.115.121.1.12 DESC 'Distinguished Name' )",
   "( 1.3.6.1.4.1.1466.115.121.1.11 DESC 'Country String' )",
   "( 1.3.6.1.4.1.1466.115.121.1.10 DESC 'Certificate Pair' " +
     "X-BINARY-TRANSFER-REQUIRED 'TRUE' X-NOT-HUMAN-READABLE 'TRUE' )",
   "( 1.3.6.1.4.1.1466.115.121.1.9 DESC 'Certificate List' " +
     "X-BINARY-TRANSFER-REQUIRED 'TRUE' X-NOT-HUMAN-READABLE 'TRUE' )",
   "( 1.3.6.1.4.1.1466.115.121.1.8 DESC 'Certificate' " +
     "X-BINARY-TRANSFER-REQUIRED 'TRUE' X-NOT-HUMAN-READABLE 'TRUE' )",
   "( 1.3.6.1.4.1.1466.115.121.1.7 DESC 'Boolean' )",
   "( 1.3.6.1.4.1.1466.115.121.1.6 DESC 'Bit String' )",
   "( 1.3.6.1.4.1.1466.115.121.1.5 DESC 'Binary' X-NOT-HUMAN-READABLE 'TRUE' )",
   "( 1.3.6.1.4.1.1466.115.121.1.4 DESC 'Audio' X-NOT-HUMAN-READABLE 'TRUE' )"
  ]

  def setup
    @schema = ActiveLdap::Schema.new("ldapSyntaxes" => SYNTAXES.dup)
    @syntaxes = {}
    @schema.ldap_syntaxes.each do |syntax|
      @syntaxes[syntax.description] = syntax
    end
  end

  def teardown
  end

  priority :must
  def test_bit_string
    assert_valid("'0101111101'B", 'Bit String')
    assert_valid("''B", 'Bit String')

    value = "0101111101"
    assert_invalid(_("%s doesn't have the first \"'\"") % value.inspect,
                   value, 'Bit String')

    value = "'0101111101'"
    assert_invalid(_("%s doesn't have the last \"'B\"") % value.inspect,
                   value, 'Bit String')

    value = "'0101111101B"
    assert_invalid(_("%s doesn't have the last \"'B\"") % value.inspect,
                   value, 'Bit String')

    value = "'0A'B"
    assert_invalid(_("%s has invalid character '%s'") % [value.inspect, "A"],
                   value, 'Bit String')
  end

  def test_boolean
    assert_valid("TRUE", "Boolean")
    assert_valid("FALSE", "Boolean")

    value = "true"
    assert_invalid(_("%s should be TRUE or FALSE") % value.inspect,
                   value, "Boolean")
  end

  def test_country_string
    assert_valid("ja", "Country String")
    assert_valid("JA", "Country String")

    value = "japan"
    assert_invalid(_("%s should be just 2 printable characters") % value.inspect,
                   value, "Country String")
  end

  def test_dn
    assert_valid("cn=test", 'Distinguished Name')
    assert_valid("CN=Steve Kille,O=Isode Limited,C=GB", 'Distinguished Name')
    assert_valid("OU=Sales+CN=J. Smith,O=Widget Inc.,C=US", 'Distinguished Name')
    assert_valid("CN=L. Eagle,O=Sue\\, Grabbit and Runn,C=GB",
                 'Distinguished Name')
    assert_valid("CN=Before\\0DAfter,O=Test,C=GB", 'Distinguished Name')
    assert_valid("1.3.6.1.4.1.1466.0=#04024869,O=Test,C=GB",
                 'Distinguished Name')
    assert_valid("SN=Lu\\C4\\8Di\\C4\\87", 'Distinguished Name')

    value = "test"
    params = [value, _("attribute value is missing")]
    assert_invalid(_('%s is invalid distinguished name (DN): %s') % params,
                   value, 'Distinguished Name')
  end

  def test_directory_string
    assert_valid("This is a string of DirectoryString containing \#!%\#@",
                 "Directory String")
    assert_valid("これはDirectoryString文字列です。",
                 "Directory String")

    value = NKF.nkf("-We", "これはDirectoryString文字列です。")
    assert_invalid(_("%s has invalid UTF-8 character") % value.inspect,
                   value, "Directory String")
  end

  def test_generalized_time
    assert_valid("199412161032", "Generalized Time")
    assert_valid("199412161032Z", "Generalized Time")
    assert_valid("199412161032+0900", "Generalized Time")

    value = "1994"
    params = [value.inspect, %w(month day hour minute).join(", ")]
    assert_invalid("%s has missing components: %s" % params,
                   value, "Generalized Time")
  end

  def test_integer
    assert_valid("1321", "Integer")

    assert_invalid_integer("13.5")
    assert_invalid_integer("string")
  end

  def test_jpeg
    assert_valid([0xffd8].pack("n"), "JPEG")

    assert_invalid(_("invalid JPEG format"), "", "JPEG")
    assert_invalid(_("invalid JPEG format"), "jpeg", "JPEG")
  end

  def test_name_and_optional_uid
    assert_valid("1.3.6.1.4.1.1466.0=#04024869,O=Test,C=GB#'0101'B",
                 "Name And Optional UID")
    assert_valid("cn=test", "Name And Optional UID")

    value = "test"
    params = [value, _("attribute value is missing")]
    assert_invalid(_('%s is invalid distinguished name (DN): %s') % params,
                   value, "Name And Optional UID")

    bit_string = "'00x'B"
    params = [bit_string.inspect, "x"]
    assert_invalid(_("%s has invalid character '%s'") % params,
                   "cn=test\##{bit_string}", "Name And Optional UID")
  end

  def test_numeric_string
    assert_valid("1997", "Numeric String")

    assert_invalid_numeric_string("-3")
    assert_invalid_numeric_string("-3.5")
    assert_invalid_numeric_string("string")
  end

  def test_oid
    assert_valid("1.2.3.4", "OID")
    assert_valid("cn", "OID")

    assert_invalid_oid("\#@!")
  end

  def test_other_mailbox
    assert_valid("smtp$bob@example.com", "Other Mailbox")


    value = "smtp"
    assert_invalid(_("%s has no mailbox") % value.inspect,
                   value, "Other Mailbox")

    value = "smtp$"
    assert_invalid(_("%s has no mailbox") % value.inspect,
                   value, "Other Mailbox")

    value = "$bob@example.com"
    assert_invalid(_("%s has no mailbox type") % value.inspect,
                   value, "Other Mailbox")

    value = "!$bob@example.com"
    params = [value.inspect, "!"]
    reason = _("%s has unprintable character in mailbox type: '%s'") % params
    assert_invalid(reason, value, "Other Mailbox")
  end

  priority :normal

  private
  def assert_valid(value, syntax_name)
    assert_nil(@syntaxes[syntax_name].validate(value))
  end

  def assert_invalid(reason, value, syntax_name)
    assert_equal(reason, @syntaxes[syntax_name].validate(value))
  end

  def assert_invalid_integer(value)
    assert_invalid(_("%s is invalid integer format") % value.inspect,
                   value, "Integer")
  end

  def assert_invalid_numeric_string(value)
    assert_invalid(_("%s is invalid numeric format") % value.inspect,
                   value, "Numeric String")
  end

  def assert_invalid_oid(value)
    assert_invalid(_("%s is invalid OID format") % value.inspect,
                   value, "OID")
  end
end
