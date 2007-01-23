require 'al-test-utils'

class TestFind < Test::Unit::TestCase
  include AlTestUtils

  def test_split_search_value
    assert_split_search_value([nil, "test-user", nil], "test-user")
    assert_split_search_value([nil, "test-user", "ou=Sub"], "test-user,ou=Sub")
    assert_split_search_value(["uid", "test-user", "ou=Sub"],
                              "uid=test-user,ou=Sub")
    assert_split_search_value(["uid", "test-user", nil], "uid=test-user")
  end

  def test_find
    make_temporary_user do |user, password|
      assert_equal(user.uid, @user_class.find(:first).uid)
      assert_equal(user.uid, @user_class.find(user.uid).uid)
      options = {:attribute => "cn", :value => user.cn}
      assert_equal(user.uid, @user_class.find(:first, options).uid)
      assert_equal(user.to_ldif, @user_class.find(:first).to_ldif)
      assert_equal([user.uid], @user_class.find(:all).collect {|u| u.uid})

      make_temporary_user do |user2, password2|
        assert_equal(user2.uid, @user_class.find(user2.uid).uid)
        assert_equal([user2.uid],
                     @user_class.find(user2.uid(true)).collect {|u| u.uid})
        assert_equal(user2.to_ldif, @user_class.find(user2.uid).to_ldif)
        assert_equal([user.uid, user2.uid].sort,
                     @user_class.find(:all).collect {|u| u.uid}.sort)
      end
    end
  end

  private
  def assert_split_search_value(expected, value)
    assert_equal(expected, ActiveLdap::Base.send(:split_search_value, value))
  end
end
