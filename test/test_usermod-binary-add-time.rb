require 'al-test-utils'

class TestUsermodBinaryAddTime < Test::Unit::TestCase
  include AlTestUtils

  def setup
    super
    @command = File.join(@examples_dir, "usermod-binary-add-time")
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
    make_temporary_user do |user, password|
      assert_usermod_binary_add_time_successfully(user.uid, "New #{user.cn}",
                                                  user.uid_number.to_i + 100)
    end
  end

  private
  def assert_usermod_binary_add_time_successfully(name, cn, uid, *args, &block)
    _wrap_assertion do
      assert(@user_class.exists?(name))
      previous_classes = @user_class.find(name).classes
      args.concat([name, cn, uid])
      assert_equal([true, ""], run_command(*args, &block))
      assert(@user_class.exists?(name))

      user = @user_class.find(name)
      assert_equal(name, user.uid)
      assert_equal(cn, user.cn)
      assert_equal(uid.to_i, user.uid_number)
      assert_equal(uid.to_i, user.gid_number)
      assert_equal(uid.to_s, user.uid_number_before_type_cast)
      assert_equal(uid.to_s, user.gid_number_before_type_cast)
      assert_equal((previous_classes + ['strongAuthenticationUser']).sort,
                   user.classes.sort)
      cert = File.read(File.join(@examples_dir, 'example.der'))
      assert_equal(cert, user.user_certificate)
    end
  end

  def assert_usermod_binary_add_time_failed(name, cn, uid, message,
                                            *args, &block)
    _wrap_assertion do
      assert(@user_class.exists?(name))
      args.concat([name, cn, uid])
      assert_equal([false, message], run_command(*args, &block))
      assert(@user_class.exists?(name))
    end
  end
end
