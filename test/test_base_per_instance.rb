require 'al-test-utils'

class BasePerInstanceTest < Test::Unit::TestCase
  include AlTestUtils

  def test_add
    ou_class("ou=Users").new("Sub").save
    make_temporary_user(:uid => "test-user,ou=Sub") do |user, password|
      assert_equal("uid=test-user,ou=Sub,#{@user_class.base}", user.dn)
      assert_equal("test-user", user.uid)
    end

    make_temporary_user(:uid => "uid=test-user,ou=Sub") do |user, password|
      assert_equal("uid=test-user,ou=Sub,#{@user_class.base}", user.dn)
      assert_equal("test-user", user.uid)
    end
  end
end
