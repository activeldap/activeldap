require 'al-test-utils'

class TestGroupmod < Test::Unit::TestCase
  include AlTestUtils

  def setup
    super
    @command = File.join(@examples_dir, "groupmod")
  end

  priority :must

  priority :normal
  def test_non_exist_group
    ensure_delete_group("test-group") do |name,|
      assert(!@group_class.exists?(name))
      assert_equal([false, "Group #{name} doesn't exist.\n"],
                   run_command(name, 111111))
      assert(!@group_class.exists?(name))
    end
  end

  def test_modify_group
    make_temporary_group do |group, password|
      assert_groupmod_successfully(group.cn, group.gid_number.succ)
    end
  end

  private
  def assert_groupmod_successfully(name, gid, *args, &block)
    _wrap_assertion do
      assert(@group_class.exists?(name))
      args.concat([name, gid])
      assert_equal([true, ""], run_command(*args, &block))
      assert(@group_class.exists?(name))

      group = @group_class.find(name)
      assert_equal(name, group.cn)
      assert_equal(gid, group.gid_number)
    end
  end

  def assert_groupmod_failed(name, gid, message, *args, &block)
    _wrap_assertion do
      assert(@group_class.exists?(name))
      args.concat([name, gid])
      assert_equal([false, message], run_command(*args, &block))
      assert(@group_class.exists?(name))
    end
  end
end
