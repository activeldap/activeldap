require 'al-test-utils'

class AttributesTest < Test::Unit::TestCase
  include AlTestUtils

  priority :must
  def test_normalize_attribute
    assert_equal(["usercertificate", [{"binary" => []}]],
                 ActiveLdap::Base.normalize_attribute("userCertificate", []))
    assert_equal(["usercertificate", [{"binary" => []}]],
                 ActiveLdap::Base.normalize_attribute("userCertificate", nil))
  end

  def test_unnormalize_attribute
    assert_equal({"userCertificate;binary" => []},
                 ActiveLdap::Base.unnormalize_attribute("userCertificate",
                                                        [{"binary" => []}]))
  end

  priority :normal
  def test_attr_protected
    user = @user_class.new(:uid => "XXX")
    assert_nil(user.uid)

    user = @user_class.new(:sn => "ZZZ")
    assert_equal("ZZZ", user.sn)

    @user_class.attr_protected :sn
    user = @user_class.new(:sn => "ZZZ")
    assert_nil(user.sn)

    sub_user_class = Class.new(@user_class)
    sub_user_class.ldap_mapping :dn_attribute => "uid"
    user = sub_user_class.new(:uid => "XXX", :sn => "ZZZ")
    assert_nil(user.uid)
    assert_nil(user.sn)

    sub_user_class.attr_protected :cn
    user = sub_user_class.new(:uid => "XXX", :sn => "ZZZ", :cn => "Common Name")
    assert_nil(user.uid)
    assert_nil(user.sn)
    assert_nil(user.cn)

    user = @user_class.new(:uid => "XXX", :sn => "ZZZ", :cn => "Common Name")
    assert_nil(user.uid)
    assert_nil(user.sn)
    assert_equal("Common Name", user.cn)
  end
end
