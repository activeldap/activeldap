require 'al-test-utils'

class TestLPasswd < Test::Unit::TestCase
  include AlTestUtils

  def setup
    super
    @command = File.join(@examples_dir, "lpasswd")
    make_ou("People")
    @user_class.prefix = "ou=People"
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

  def test_change_password
    make_temporary_user do |user, password|
      new_password = "new#{password}"
      assert_lpasswd_successfully(user.uid, password, new_password)
    end
  end

  def test_password_mismatch
    make_temporary_user do |user, password|
      message = "[#{user.dn}] Password: \n" * 2
      message = "#{message}Password mismatch!\n" * 3
      assert_lpasswd_failed(user.id, password, message) do |input, output|
        3.times do
          output.puts("new#{password}1")
          output.puts("new#{password}2")
          output.flush
        end
      end
    end
  end

  private
  def assert_lpasswd_successfully(name, current, new, *args, &block)
    _wrap_assertion do
      assert(@user_class.exists?(name))
      assert_send([ActiveLdap::UserPassword, :valid?,
                   current, @user_class.find(name).user_password])
      args.concat([name])
      block ||=  Proc.new do |input, output|
        output.puts(new)
        output.puts(new)
        output.flush
      end
      assert_equal([true, "[#{@user_class.find(name).dn}] Password: \n" * 2],
                   run_command(*args, &block))
      assert_send([ActiveLdap::UserPassword, :valid?,
                   new, @user_class.find(name).user_password])
    end
  end

  def assert_lpasswd_failed(name, current, message, *args, &block)
    _wrap_assertion do
      assert(@user_class.exists?(name))
      assert_send([ActiveLdap::UserPassword, :valid?,
                   current, @user_class.find(name).user_password])
      args.concat([name])
      assert_equal([false, message], run_command(*args, &block))
      assert_send([ActiveLdap::UserPassword, :valid?,
                   current, @user_class.find(name).user_password])
    end
  end
end
