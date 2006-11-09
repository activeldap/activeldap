require 'al-test-utils'

class UserLsTest < Test::Unit::TestCase
  include AlTestUtils

  def setup
    super
    @command = File.join(@examples_dir, "userls")
    make_ou("People")
    @user_class.instance_variable_set("@prefix", "ou=People")
  end

  priority :must

  priority :normal
  def test_non_exist_user
    ensure_delete_user("test-user") do |uid,|
      assert(!@user_class.exists?(uid))
      assert_equal([false, "User #{uid} doesn't exist.\n"], run_command(uid))
      assert(!@user_class.exists?(uid))
    end
  end

  def test_list_user_no_group
    make_temporary_user do |user, password|
      assert_userls_successfully(user.uid, [])
    end
  end

  def test_list_user_have_primary_group
    make_temporary_group do |group|
      make_temporary_user(:gid_number => group.gid_number) do |user, password|
        assert_userls_successfully(user.uid, [group])
      end
    end
  end

  def test_list_user_have_groups
    make_temporary_group do |group1|
      make_temporary_group do |group2|
        options = {:gid_number => group2.gid_number.succ}
        make_temporary_user(options) do |user, password|
          user.groups << group1
          user.groups << group2
          assert_userls_successfully(user.uid, [group1, group2])
        end
      end
    end
  end

  def test_list_user_have_primary_group
    make_temporary_group do |group1|
      make_temporary_user(:gid_number => group1.gid_number) do |user, password|
        make_temporary_group do |group2|
          make_temporary_group do |group3|
            user.groups << group2
            user.groups << group3
            assert_userls_successfully(user.uid, [group1, group2, group3])
          end
        end
      end
    end
  end

  private
  def assert_userls_successfully(name, groups, *args, &block)
    _wrap_assertion do
      assert(@user_class.exists?(name))
      args.concat([name])
      user = @user_class.find(name)
      groups = groups.collect {|g| "#{g.cn}[#{g.gid_number}]"}
      result = "#{user.to_ldif}Groups: #{groups.join(', ')}\n"
      assert_equal([true, result], run_command(*args, &block))
      assert(@user_class.exists?(name))
    end
  end

  def assert_userls_failed(name, message, *args, &block)
    _wrap_assertion do
      assert(@user_class.exists?(name))
      args.concat([name])
      assert_equal([false, message], run_command(*args, &block))
      assert(@user_class.exists?(name))
    end
  end
end
