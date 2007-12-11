require 'al-test-utils'

class TestLoad < Test::Unit::TestCase
  include AlTestUtils

  priority :must
  def test_load_modify_record
    ldif = ActiveLdap::LDIF.new
    make_temporary_user do |user, password|
      user.display_name = "Display Name"
      assert(user.save)

      user = @user_class.find(user.dn)
      assert_equal("Display Name", user.display_name)

      record = ActiveLdap::LDIF::ModifyRecord.new(user.dn)
      ldif << record

      original_descriptions = user.description(true)
      new_description = "new description"
      record.add_operation(:add, "description", [],
                           {"description" => [new_description]})

      record.add_operation(:delete, "DisplayName", [], {})

      original_sn = user.sn
      new_sn = ["New SN1", "New SN2"]
      record.add_operation(:replace, "sn", [], {"sn" => new_sn})

      ActiveLdap::Base.load(ldif.to_s)

      user = @user_class.find(user.dn)
      assert_equal(original_descriptions + [new_description],
                   user.description(true))
      assert_nil(user.display_name)
      assert_equal(new_sn, user.sn)
    end
  end

  def test_load_move_dn_record
    assert_load_move_dn_record(ActiveLdap::LDIF::ModifyDNRecord)
    assert_load_move_dn_record(ActiveLdap::LDIF::ModifyRDNRecord)
  end

  def test_load_copy_dn_record
    assert_load_copy_dn_record(ActiveLdap::LDIF::ModifyDNRecord)
    assert_load_copy_dn_record(ActiveLdap::LDIF::ModifyRDNRecord)
  end

  def test_load_delete_record
    ldif = ActiveLdap::LDIF.new
    make_temporary_user do |user, password|
      record = ActiveLdap::LDIF::DeleteRecord.new(user.dn)
      ldif << record
      assert_true(@user_class.exists?(user.dn))
      ActiveLdap::Base.load(ldif.to_s)
      assert_false(@user_class.exists?(user.dn))
    end
  end

  def test_load_add_record
    ldif = ActiveLdap::LDIF.new
    make_temporary_user do |user, password|
      new_description = "new description"
      attributes = {
        "description" => [new_description]
      }
      original_descriptions = user.description(true)
      record = ActiveLdap::LDIF::AddRecord.new(user.dn, [], attributes)
      ldif << record
      ActiveLdap::Base.load(ldif.to_s)
      user.reload
      assert(original_descriptions + [new_description], user.description(true))
    end
  end

  def test_load_content_records
    ldif = ActiveLdap::LDIF.new
    2.times do
      make_temporary_user do |user, password|
        ldif << ActiveLdap::LDIF.parse(user.to_ldif).records[0]
      end
    end

    original_n_users = @user_class.count
    ActiveLdap::Base.load(ldif.to_s)
    assert_equal(2, @user_class.count - original_n_users)
  end

  priority :normal

  private
  def assert_load_copy_dn_record(record_class)
    ldif = ActiveLdap::LDIF.new
    make_temporary_user do |user, password|
      new_rdn = "uid=XXX"
      ensure_delete_user(new_rdn) do
        record = record_class.new(user.dn, [], new_rdn, false)
        ldif << record
        assert_true(@user_class.exists?(user.dn))
        assert_false(@user_class.exists?(new_rdn))
        ActiveLdap::Base.load(ldif.to_s)
        assert_true(@user_class.exists?(user.dn))
        assert_true(@user_class.exists?(new_rdn))
        assert_equal(user.cn, @user_class.find(new_rdn).cn)
      end
    end
  end

  def assert_load_move_dn_record(record_class)
    ldif = ActiveLdap::LDIF.new
    make_temporary_user do |user, password|
      new_rdn = "uid=XXX"
      ensure_delete_user(new_rdn) do
        record = record_class.new(user.dn, [], new_rdn, true)
        ldif << record
        assert_true(@user_class.exists?(user.dn))
        assert_false(@user_class.exists?(new_rdn))
        ActiveLdap::Base.load(ldif.to_s)
        assert_false(@user_class.exists?(user.dn))
        assert_true(@user_class.exists?(new_rdn))
        assert_equal(user.cn, @user_class.find(new_rdn).cn)
      end
    end
  end
end
