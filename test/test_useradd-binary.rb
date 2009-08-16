require 'al-test-utils'

class TestUseraddBinary < Test::Unit::TestCase
  include AlTestUtils

  def setup
    super
    @command = File.join(@examples_dir, "useradd-binary")
    make_ou("People")
    @user_class.prefix = "ou=People"
  end

  priority :must

  priority :normal
  def test_exist_user
    make_temporary_user do |user, password|
      assert(@user_class.exists?(user.uid))
      assert_equal([false, "User #{user.uid} already exists.\n"],
                   run_command(user.uid, user.cn, user.uid_number))
      assert(@user_class.exists?(user.uid))
    end
  end

  def test_add_user
    ensure_delete_user("test-user") do |uid,|
      assert_useradd_binary_successfully(uid, uid, 10000)
    end
  end

  private
  def assert_useradd_binary_successfully(name, cn, uid, *args, &block)
    _wrap_assertion do
      assert(!@user_class.exists?(name))
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
      assert_equal(['person', 'posixAccount', 'shadowAccount',
                    'strongAuthenticationUser'].sort, user.classes.sort)
      cert = File.read(File.join(@examples_dir, 'example.der'))
      cert.force_encoding('ascii-8bit') if cert.respond_to?(:force_encoding)
      assert_equal(cert, user.user_certificate)
    end
  end

  def assert_useradd_binary_failed(name, cn, uid, message, *args, &block)
    _wrap_assertion do
      assert(!@user_class.exists?(name))
      args.concat([name, cn, uid])
      assert_equal([false, message], run_command(*args, &block))
      assert(!@user_class.exists?(name))
    end
  end
end
