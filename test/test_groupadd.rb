require 'al-test-utils'

class TestGroupadd < Test::Unit::TestCase
  include AlTestUtils

  def setup
    super
    @command = File.join(@examples_dir, "groupadd")
  end

  priority :must

  priority :normal
  def test_exist_group
    make_temporary_group do |group|
      assert(@group_class.exists?(group.id))
      assert_equal([false, "Group #{group.id} already exists.\n"],
                   run_command(group.id))
      assert(@group_class.exists?(group.id))
    end
  end

  def test_add_group
    ensure_delete_group("test-group") do |gid|
      assert_groupadd_successfully(gid)
    end
  end

  private
  def assert_groupadd_successfully(name, *args, &block)
    _wrap_assertion do
      assert(!@group_class.exists?(name))
      args.concat([name])
      assert_equal([true, ""], run_command(*args, &block))
      assert(@group_class.exists?(name))

      group = @group_class.find(name)
      assert_equal(name, group.id)
    end
  end

  def assert_groupadd_failed(name, message, *args, &block)
    _wrap_assertion do
      assert(!@group_class.exists?(name))
      args.concat([name])
      assert_equal([false, message], run_command(*args, &block))
      assert(!@group_class.exists?(name))
    end
  end
end
