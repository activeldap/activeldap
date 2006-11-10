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
    assert_equal("XXX", user.uid)

    @user_class.attr_protected :uid
    user = @user_class.new(:uid => "XXX")
    assert_nil(user.uid)

    sub_user_class = Class.new(@user_class)
    user = sub_user_class.new(:uid => "XXX")
    assert_nil(user.uid)

    sub_user_class.attr_protected :cn
    user = sub_user_class.new(:uid => "XXX", :cn => "Common Name")
    assert_nil(user.uid)
    assert_nil(user.cn)

    user = @user_class.new(:uid => "XXX", :cn => "Common Name")
    assert_nil(user.uid)
    assert_equal("Common Name", user.cn)
  end
end
