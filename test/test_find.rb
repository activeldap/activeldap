require 'al-test-utils'

class TestFind < Test::Unit::TestCase
  include AlTestUtils

  def test_find_paged
    # The default page size is 126.
    n_users = 127
    uids = n_users.times.collect do
      user, _password = make_temporary_user
      user.uid
    end
    assert_equal(uids.sort,
                 @user_class.find(:all).collect(&:uid).sort)
  end

  def test_find_with_dn
    make_temporary_user do |user,|
      assert_equal(user.dn, @user_class.find(user.dn).dn)
      assert_equal(user.dn, @user_class.find(ActiveLdap::DN.parse(user.dn)).dn)
    end
  end

  def test_find_with_special_value_prefix
    # \2C == ','
    make_ou("a\\2Cb,ou=Users")
    make_temporary_user(:uid => "user1,ou=a\\2Cb") do |user1,|
      assert_equal([], @user_class.find(:all, :prefix => "ou=a,b").collect(&:dn))
      params = {:prefix => "ou=a\\2Cb"}
      assert_equal([user1.dn], @user_class.find(:all, params).collect(&:dn))
      params = {:prefix => [["ou", "a,b"]]}
      assert_equal([user1.dn], @user_class.find(:all, params).collect(&:dn))
    end
  end

  def test_find_with_special_value_base
    # \5C == '\'
    make_ou("a\\5Cb,ou=Users")
    make_temporary_user(:uid => "user1,ou=a\\5Cb") do |user1,|
      base = @user_class.base
      params = {:base => "ou=a\\b,#{base}"}
      assert_equal([], @user_class.find(:all, params).collect(&:dn))
      params = {:base => "ou=a\\5Cb,#{base}"}
      assert_equal([user1.dn], @user_class.find(:all, params).collect(&:dn))
      base_rdns = ActiveLdap::DN.parse(base).rdns
      params = {:base => [["ou", "a\\b"]] + base_rdns}
      assert_equal([user1.dn], @user_class.find(:all, params).collect(&:dn))
    end
  end

  def test_find_with_sort_by_in_ldap_mapping
    @user_class.ldap_mapping(:dn_attribute => @user_class.dn_attribute,
                             :prefix => @user_class.prefix,
                             :scope => @user_class.scope,
                             :classes => @user_class_classes,
                             :sort_by => "uid",
                             :order => "desc")
    make_temporary_user(:uid => "user1") do |user1,|
      make_temporary_user(:uid => "user2") do |user2,|
        make_temporary_user(:uid => "user3") do |user3,|
          users = @user_class.find(:all)
          assert_equal(["user3", "user2", "user1"],
                       users.collect {|u| u.uid})

          users = @user_class.find(:all, :order => "asc")
          assert_equal(["user1", "user2", "user3"],
                       users.collect {|u| u.uid})
        end
      end
    end
  end

  def test_find_operational_attributes
    make_temporary_user do |user, password|
      found_user = @user_class.find(user.uid,
                                    :include_operational_attributes => true)
      assert_equal(Time.now.utc.iso8601,
                   found_user.modify_timestamp.utc.iso8601)
    end
  end

  def test_find_with_attributes_without_object_class
    make_temporary_user do |user, password|
      found_user = @user_class.find(user.uid, :attributes => ["uidNumber"])
      assert_equal(user.uid_number, found_user.uid_number)
      assert_equal(user.classes, found_user.classes)
      assert_nil(found_user.gid_number)
    end
  end

  def test_find_with_integer_value
    make_temporary_user do |user, password|
      found_user = @user_class.find(:attribute => "gidNumber",
                                    :value => user.gid_number)
      assert_equal(user.dn, found_user.dn)
    end
  end

  def test_find_with_limit
    make_temporary_user(:uid => "user1") do |user1,|
      make_temporary_user(:uid => "user2") do |user2,|
        make_temporary_user(:uid => "user3") do |user3,|
          users = @user_class.find(:all)
          assert_equal(["user1", "user2", "user3"].sort,
                       users.collect {|u| u.uid}.sort)

          users = @user_class.find(:all, :limit => 2)
          assert_operator([["user1", "user2"].sort,
                           ["user2", "user3"].sort,
                           ["user3", "user1"].sort],
                          :include?,
                          users.collect {|u| u.uid}.sort)

          users = @user_class.find(:all, :limit => 1)
          assert_operator([["user1"], ["user2"], ["user3"]],
                          :include?,
                          users.collect {|u| u.uid})
        end
      end
    end
  end

  def test_find_all_with_dn_attribute_value
    make_temporary_user(:uid => "user1") do |user1,|
      make_temporary_user(:uid => "user2") do |user2,|
        assert_equal(["user1"],
                     @user_class.find(:all, "*1").collect {|u| u.uid})
      end
    end
  end

  def test_find_with_sort
    make_temporary_user(:uid => "user1") do |user1,|
      make_temporary_user(:uid => "user2") do |user2,|
        users = @user_class.find(:all, :sort_by => "uid", :order => 'asc')
        assert_equal(["user1", "user2"], users.collect {|u| u.uid})
        users = @user_class.find(:all, :sort_by => "uid", :order => 'desc')
        assert_equal(["user2", "user1"], users.collect {|u| u.uid})

        users = @user_class.find(:all, :order => 'asc')
        assert_equal(["user1", "user2"], users.collect {|u| u.uid})
        users = @user_class.find(:all, :order => 'desc')
        assert_equal(["user2", "user1"], users.collect {|u| u.uid})

        users = @user_class.find(:all, :order => 'asc', :limit => 1)
        assert_equal(["user1"], users.collect {|u| u.uid})
        users = @user_class.find(:all, :order => 'desc', :limit => 1)
        assert_equal(["user2"], users.collect {|u| u.uid})
      end
    end
  end

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
      assert_equal(user.uid, @user_class.find(options).uid)
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
