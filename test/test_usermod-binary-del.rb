require 'al-test-utils'

class UserModBinaryDelTest < Test::Unit::TestCase
  include AlTestUtils

  def setup
    super
    @command = File.join(@examples_dir, "usermod-binary-del")
    make_ou("People")
    @user_class.instance_variable_set("@prefix", "ou=People")
  end

  priority :must

 priority :normal
  def test_non_exist_user
    ensure_delete_user("test-user") do |uid,|
      assert(!@user_class.exists?(uid))
      assert_equal([false, "User #{uid} doesn't exist.\n"],
                   run_command(uid, "New CN", 11111))
      assert(!@user_class.exists?(uid))
    end
  end

  def test_modify_user
    make_temporary_user(:simple => true) do |user, password|
      user.add_class("strongAuthenticationUser")
      user.user_certificate = certificate
      assert(user.save)
      assert_usermod_binary_del_successfully(user.uid, "New #{user.cn}",
                                             user.uid_number.to_i + 100)
    end
  end

  private
  def assert_usermod_binary_del_successfully(name, cn, uid, *args, &block)
    _wrap_assertion do
      assert(@user_class.exists?(name))
      previous_classes = @user_class.find(name).classes
      assert_operator(previous_classes, :include?, "strongAuthenticationUser")
      args.concat([name, cn, uid])
      assert_equal([true, ""], run_command(*args, &block))
      assert(@user_class.exists?(name))

      user = @user_class.find(name)
      assert_equal(name, user.uid)
      assert_equal(cn, user.cn)
      assert_equal(uid.to_s, user.uid_number)
      assert_equal(uid.to_s, user.gid_number)
      assert_equal((previous_classes - ['strongAuthenticationUser']).sort,
                   user.classes.sort)
      assert(!user.respond_to?(:user_certificate))
    end
  end

  def assert_usermod_binary_del_failed(name, cn, uid, message, *args, &block)
    _wrap_assertion do
      assert(@user_class.exists?(name))
      args.concat([name, cn, uid])
      assert_equal([false, message], run_command(*args, &block))
      assert(@user_class.exists?(name))
    end
  end
end
