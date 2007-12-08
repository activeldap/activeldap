require 'al-test-utils'

class TestLoad < Test::Unit::TestCase
  include AlTestUtils

  priority :must
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
end
