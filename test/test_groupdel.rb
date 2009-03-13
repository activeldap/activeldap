require 'al-test-utils'

class TestGroupdel < Test::Unit::TestCase
  include AlTestUtils

  def setup
    super
    @command = File.join(@examples_dir, "groupdel")
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

  def test_delete_group
    make_temporary_group do |group|
      assert_groupdel_successfully(group.id)
    end
  end

  private
  def assert_groupdel_successfully(name, *args, &block)
    _wrap_assertion do
      assert(@group_class.exists?(name))
      args.concat([name])
      assert_equal([true, ""], run_command(*args, &block))
      assert(!@group_class.exists?(name))
    end
  end

  def assert_groupdel_failed(name, message, *args, &block)
    _wrap_assertion do
      assert(@group_class.exists?(name))
      args.concat([name])
      assert_equal([false, message], run_command(*args, &block))
      assert(@group_class.exists?(name))
    end
  end
end
