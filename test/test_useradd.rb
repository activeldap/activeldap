require 'al-test-utils'

class UserAddTest < Test::Unit::TestCase
  include AlTestUtils

  def setup
    super
    @useradd = File.join(@examples_dir, "useradd")
    make_ou("People")
    @user_class.instance_variable_set("@prefix", "ou=People")
  end

  priority :must
  def test_exist_user
    make_temporary_user do |user, password|
      assert(@user_class.exists?(user.uid))
      assert_equal([false, "User #{user.uid} already exists.\n"],
                   run_useradd(user.uid, user.cn, user.uid_number))
      assert(@user_class.exists?(user.uid))
    end
  end

  def test_add_user
    ensure_delete_user("test-user") do |uid,|
      assert_useradd_successfully(uid, uid, 10000)
    end
  end

  private
  def run_useradd(*other_args, &block)
    file = Tempfile.new("useradd")
    file.open
    file.puts(establish_connection_config.to_yaml)
    file.close
    run_ruby(*[@useradd, "--config", file.path, *other_args], &block)
  end

  def assert_useradd_successfully(name, sn, uid, *args)
    _wrap_assertion do
      assert(!@user_class.exists?(name))
      args.concat([name, sn, uid])
      assert_equal([true, ""], run_useradd(*args))
      assert(@user_class.exists?(name))
    end
  end

  def assert_useradd_failed(name, sn, uid, message, *args)
    _wrap_assertion do
      assert(!@user_class.exists?(name))
      args.concat([name, sn, uid])
      assert_equal([false, message], run_useradd(*args))
      assert(!@user_class.exists?(name))
    end
  end
end
