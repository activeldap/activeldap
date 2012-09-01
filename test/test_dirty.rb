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
      assert_true(user.cn_changed?)
      user.reload
      assert_false(user.cn_changed?)

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
      assert_true(user.cn_changed?)

      _wrap_assertion do
        (attributes - ['cn']).each do |name|
          assert_false(user.send("#{name}_changed?"))
        end

        assert_true(user.cn_changed?)
      end
    end
  end

  def test_save
    make_temporary_user do |user, password|
      attributes = (user.must + user.may).collect(&:name) - ['objectClass', 'cn']
      user.cn = 'New cn'
      assert_true(user.cn_changed?)
      user.save
      assert_false(user.cn_changed?)

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
      assert_true(user.cn_changed?)
      user.save!
      assert_false(user.cn_changed?)

      _wrap_assertion do
        attributes.each do |name|
          assert_false(user.send("#{name}_changed?"))
        end
      end
    end
  end

  class TestDNChange
    def test_direct_base_use
      leaf = ActiveLdap::Base.create
      leaf.add_class("organizationalUnit")
      leaf_dn = "ou=addressbook,#{user.dn}"
      leaf.dn = leaf_dn
      begin
        leaf.save
      ensure
        ActiveLdap::Base.delete_entry(leaf_dn) if leaf.exists?
      end
    end
  end
end
