require 'al-test-utils'

class TestActsAsTree < Test::Unit::TestCase
  include AlTestUtils

  priority :must

  priority :normal
  def test_children
    users = ou_class.find("Users")
    assert_equal([], users.children.collect(&:ou))

    sub_users = users.class.new("SubUsers")
    users.children << sub_users
    assert_equal(["SubUsers"], users.children.collect(&:ou))

    users = ou_class.find("Users")
    assert_equal(["SubUsers"], users.children.collect(&:ou))

    assert_equal("ou=SubUsers,#{users.dn}", sub_users.dn)

    assert(ou_class.exists?("SubUsers"))
    users.children.replace([])
    assert(!ou_class.exists?("SubUsers"))
    assert_equal([], users.children.collect(&:ou))
  end

  def test_parent
    users = ou_class.find("Users")
    assert_equal([], users.children.collect(&:ou))

    sub_users = users.class.new("SubUsers")
    sub_users.parent = users
    assert_equal("ou=SubUsers,#{users.dn}", sub_users.dn)
    assert_equal(["SubUsers"], users.children.collect(&:ou))

    sub_users = ou_class.find("SubUsers")
    assert_equal(users.dn, sub_users.parent.dn)

    assert_raises(ArgumentError) do
      sub_users.parent = nil
    end

    make_ou("OtherUsers")
    other_users = ou_class.find("OtherUsers")
    assert_equal([], other_users.children.collect(&:ou))

    sub_users.parent = other_users.dn
    assert_equal("ou=SubUsers,#{other_users.dn}", sub_users.dn)

    other_users.clear_association_cache
    assert_equal(["SubUsers"], other_users.children.collect(&:ou))

    users.clear_association_cache
    assert_equal([], users.children.collect(&:ou))
  end
end
