require 'al-test-utils'

class UserDelTest < Test::Unit::TestCase
  include AlTestUtils

  def setup
    super
    @command = File.join(@examples_dir, "userdel")
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

  def test_delete_user
    make_temporary_user do |user, password|
      assert_userdel_successfully(user.uid)
    end
  end

  private
  def assert_userdel_successfully(name, *args, &block)
    _wrap_assertion do
      assert(@user_class.exists?(name))
      args.concat([name])
      assert_equal([true, ""], run_command(*args, &block))
      assert(!@user_class.exists?(name))
    end
  end

  def assert_userdel_failed(name, message, *args, &block)
    _wrap_assertion do
      assert(@user_class.exists?(name))
      args.concat([name])
      assert_equal([false, message], run_command(*args, &block))
      assert(@user_class.exists?(name))
    end
  end
end
