require 'al-test-utils'

class TestDN < Test::Unit::TestCase
  include AlTestUtils

  def setup
  end

  def teardown
  end

  priority :must
  def test_parse_good_manner_dn
    assert_dn([["dc", "local"], ["dc", "net"]], "dc=local,dc=net")
    assert_dn([["dc", "net"]], "dc=net")
    assert_dn([], "")
  end

  def test_parse_dn_with_space
    assert_dn([["dc", "net"]], "dc =net")
    assert_dn([["dc", "net"]], "dc = net")
    assert_dn([["dc", "local"], ["dc", "net"]], "dc = local , dc = net")
    assert_dn([["dc", "local"], ["dc", "net "]], "dc = local , dc = net ")
  end

  def test_parse_dn_with_hex_pairs
    assert_dn([["dc", "local"], ["dc", "net"]],
              "dc = #6C6f63616C , dc = net")
    assert_dn([["dc", "lo cal "], ["dc", "net"]],
              "dc = #6C6f2063616C20 ,dc=net")
  end

  def test_parse_dn_in_rfc2253
    assert_dn([
               {"cn" => "Steve Kille"},
               {"o" => "Isode Limited"},
               {"c" => "GB"}
              ],
              "CN=Steve Kille,O=Isode Limited,C=GB")
    assert_dn([
               {"ou" => "Sales", "cn" => "J. Smith"},
               {"o" => "Widget Inc."},
               {"c" => "US"},
              ],
              "OU=Sales+CN=J. Smith,O=Widget Inc.,C=US")
    assert_dn([
               {"cn" => "L. Eagle"},
               {"o" => "Sue, Grabbit and Runn"},
               {"c" => "GB"},
              ],
              "CN=L. Eagle,O=Sue\\, Grabbit and Runn,C=GB")
    assert_dn([
               {"cn" => "Before\rAfter"},
               {"o" => "Test"},
               {"c" => "GB"}
              ],
              "CN=Before\\0DAfter,O=Test,C=GB")
    assert_dn([
               {"1.3.6.1.4.1.1466.0" => [0x04, 0x02, 0x48, 0x69].pack("C*")},
               {"o" => "Test"},
               {"c" => "GB"}
              ],
              "1.3.6.1.4.1.1466.0=#04024869,O=Test,C=GB")
    assert_dn([{"sn" => "Lučić"}], "SN=Lu\\C4\\8Di\\C4\\87")
  end

  def test_parse_invalid_dn
    assert_invalid_dn("attribute value is missing", "net")
    assert_invalid_dn("attribute value is missing", "local,dc=net")
    assert_invalid_dn("attribute value is missing", "dc=,dc=net")
    assert_invalid_dn("attribute type is missing", "=local,dc=net")
    assert_invalid_dn("name component is missing", ",dc=net")
    assert_invalid_dn("name component is missing", "dc=local,")
  end

  def test_parse_quoted_comma_dn
    assert_dn([["dc", "local,"]], "dc=local\\,")
  end

  def test_parser_collect_pairs
    assert_dn_parser_collect_pairs(",", "\\,")
  end

  priority :normal

  private
  def assert_dn(expected, dn)
    assert_equal(ActiveLdap::DN.new(*expected), ActiveLdap::DN.parse(dn))
  end

  def assert_invalid_dn(reason, dn)
    exception = nil
    assert_raise(ActiveLdap::DistinguishedNameInvalid) do
      begin
        ActiveLdap::DN.parse(dn)
      rescue Exception
        exception = $!
        raise
      end
    end
    assert_not_nil(exception)
    assert_equal(dn, exception.dn)
    assert_equal(reason, exception.reason)
  end

  def assert_dn_parser_collect_pairs(expected, source)
    parser = ActiveLdap::DN::Parser.new(source)
    assert_equal(expected,
                 parser.send(:collect_pairs, StringScanner.new(source)))
  end
end
