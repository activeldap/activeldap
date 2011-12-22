require 'al-test-utils'

class TestDirty < Test::Unit::TestCase
  include AlTestUtils

  priority :must

  priority :normal
  def test_clean_after_load
    make_temporary_user do |user, password|
      attributes = (user.must + user.may).collect(&:name) - ['objectClass']
      _wrap_assertion do
        attributes.each do |name|
          assert_false(user.send("#{name}_changed?"))
        end
      end
    end
  end

  def test_clean_after_reload
    make_temporary_user do |user, password|
      attributes = (user.must + user.may).collect(&:name) - ['objectClass']

      user.cn = 'New cn'
      user.reload

      _wrap_assertion do
        attributes.each do |name|
          assert_false(user.send("#{name}_changed?"))
        end
      end
    end
  end

  def test_setter
    make_temporary_user do |user, password|
      attributes = (user.must + user.may).collect(&:name) - ['objectClass', 'cn']
      user.cn = 'New cn'

      _wrap_assertion do
        (attributes - ['cn']).each do |name|
          assert_false(user.send("#{name}_changed?"))
        end

        assert(user.cn_changed?)
      end
    end
  end

  def test_save
    make_temporary_user do |user, password|
      attributes = (user.must + user.may).collect(&:name) - ['objectClass', 'cn']
      user.cn = 'New cn'
      user.save
      _wrap_assertion do
        attributes.each do |name|
          assert_false(user.send("#{name}_changed?"))
        end
      end
    end
  end

  def test_save!
    make_temporary_user do |user, password|
      attributes = (user.must + user.may).collect(&:name) - ['objectClass', 'cn']
      user.cn = 'New cn'
      user.save!
      _wrap_assertion do
        attributes.each do |name|
          assert_false(user.send("#{name}_changed?"))
        end
      end
    end
  end

end
