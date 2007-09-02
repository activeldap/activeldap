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
  def test_dn
    assert_valid('Distinguished Name', "cn=test")

    value = "test"
    params = [value, _("attribute value is missing")]
    assert_invalid(_('%s is invalid distinguished name (DN): %s') % params,
                   'Distinguished Name', value)
  end

  priority :normal

  private
  def assert_valid(syntax_name, value)
    assert_nil(@syntaxes[syntax_name].validate(value))
  end

  def assert_invalid(reason, syntax_name, value)
    assert_equal(reason, @syntaxes[syntax_name].validate(value))
  end
end
