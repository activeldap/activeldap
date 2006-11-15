require 'al-test-utils'

class TestBasePerInstance < Test::Unit::TestCase
  include AlTestUtils

  priority :must
  def test_exists?
    ou_class("ou=Users").new("Sub").save
    make_temporary_user(:uid => "test-user,ou=Sub") do |user, password|
      assert(@user_class.exists?(user.uid))
      assert(@user_class.exists?("uid=#{user.uid}"))
      assert(@user_class.exists?(user.dn))

      assert(@user_class.exists?("test-user,ou=Sub"))
      assert(@user_class.exists?("uid=test-user,ou=Sub"))
    end
  end

  priority :normal
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
