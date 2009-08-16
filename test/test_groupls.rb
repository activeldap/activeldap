require 'al-test-utils'

class TestGroupls < Test::Unit::TestCase
  include AlTestUtils

  def setup
    super
    @command = File.join(@examples_dir, "groupls")
    make_ou("People")
    @user_class.prefix = "ou=People"
  end

  priority :must

  priority :normal
  def test_non_exist_group
    ensure_delete_group("test-group") do |name|
      assert(!@group_class.exists?(name))
      assert_equal([false, "Group #{name} doesn't exist.\n"], run_command(name))
      assert(!@group_class.exists?(name))
    end
  end

  def test_list_group_no_group
    make_temporary_group do |group|
      assert_groupls_successfully(group.id, [])
    end
  end

  def test_list_group_have_primary_members
    make_temporary_group do |group|
      make_temporary_user(:gid_number => group.gid_number) do |user1,|
        make_temporary_user(:gid_number => group.gid_number) do |user2,|
          assert_groupls_successfully(group.id, [user1, user2])
        end
      end
    end
  end

  def test_list_group_have_members
    make_temporary_user do |user1,|
      make_temporary_user do |user2,|
        make_temporary_group do |group|
          group.members << user1
          group.members << user2
          assert_groupls_successfully(group.id, [user1, user2])
        end
      end
    end
  end

  def test_list_group_have_members_and_primary_members
    make_temporary_group do |group|
      options = {:gid_number => group.gid_number}
      make_temporary_user(options) do |primary_user1,|
        make_temporary_user(options) do |primary_user2,|
          options1 = {:gid_number => group.gid_number.succ}
          options2 = {:gid_number => group.gid_number.succ.succ}
          make_temporary_user(options1) do |user1,|
            make_temporary_user(options2) do |user2,|
              group.members << user1
              group.members << user2
              assert_groupls_successfully(group.id,
                                          [primary_user1, primary_user2,
                                           user1, user2])
            end
          end
        end
      end
    end
  end

  def test_list_group_have_non_exist_member
    make_temporary_group do |group|
      options = {:gid_number => group.gid_number.succ}
      make_temporary_user(options) do |user,|
        group.member_uid = [user.id]
        assert(group.save)
        assert_groupls_successfully(group.id, [user])
      end
    end
  end

  private
  def assert_groupls_successfully(name, members, *args, &block)
    _wrap_assertion do
      assert(@group_class.exists?(name))
      args.concat([name])
      group = @group_class.find(name)
      members = members.collect do |m|
        "#{m.uid}[#{m.new_entry? ? '????' : m.uid_number}]"
      end
      result = "#{group.cn}(#{group.gid_number}): #{members.join(', ')}\n"
      assert_equal([true, result], run_command(*args, &block))
      assert(@group_class.exists?(name))
    end
  end

  def assert_groupls_failed(name, message, *args, &block)
    _wrap_assertion do
      assert(@group_class.exists?(name))
      args.concat([name])
      assert_equal([false, message], run_command(*args, &block))
      assert(@group_class.exists?(name))
    end
  end
end
