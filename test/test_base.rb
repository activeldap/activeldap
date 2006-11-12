require 'al-test-utils'

class BaseTest < Test::Unit::TestCase
  include AlTestUtils

  priority :must
  def test_compare
    make_temporary_user do |user1,|
      make_temporary_user do |user2,|
        make_temporary_user do |user3,|
          make_temporary_user do |user4,|
            actual = ([user1, user2, user3] & [user1, user4])
            assert_equal([user1].collect {|user| user.id},
                         actual.collect {|user| user.id})
          end
        end
      end
    end
  end

  priority :normal
  def test_ldap_mapping_validation
    ou_class = Class.new(ActiveLdap::Base)
    assert_raises(ArgumentError) do
      ou_class.ldap_mapping :dnattr => "ou"
    end

    assert_nothing_raised do
      ou_class.ldap_mapping :dn_attribute => "ou",
                            :prefix => "",
                            :classes => ["top", "organizationalUnit"]
    end
  end

  def test_to_xml
    ou = ou_class.new("Sample")
    assert_equal(<<-EOX, ou.to_xml(:root => "ou"))
<ou>
  <dn>#{ou.dn}</dn>
  <objectClass>organizationalUnit</objectClass>
  <objectClass>top</objectClass>
  <ou>Sample</ou>
</ou>
EOX

    assert_equal(<<-EOX, ou.to_xml)
<>
  <dn>#{ou.dn}</dn>
  <objectClass>organizationalUnit</objectClass>
  <objectClass>top</objectClass>
  <ou>Sample</ou>
</>
EOX

    make_temporary_user do |user, password|
    assert_equal(<<-EOX, user.to_xml(:root => "user"))
<user>
  <dn>#{user.dn}</dn>
  <cn>#{user.cn}</cn>
  <gidNumber>#{user.gid_number}</gidNumber>
  <homeDirectory>#{user.home_directory}</homeDirectory>
  <jpegPhoto>#{jpeg_photo}</jpegPhoto>
  <objectClass>inetOrgPerson</objectClass>
  <objectClass>organizationalPerson</objectClass>
  <objectClass>person</objectClass>
  <objectClass>posixAccount</objectClass>
  <objectClass>shadowAccount</objectClass>
  <sn>#{user.sn}</sn>
  <uid>#{user.uid}</uid>
  <uidNumber>#{user.uid_number}</uidNumber>
  <userCertificate binary="true">#{certificate}</userCertificate>
  <userPassword>#{user.user_password}</userPassword>
</user>
EOX
    end
  end

  def test_save
    make_temporary_user do |user, password|
      user.sn = nil
      assert(!user.save)
      assert_raises(ActiveLdap::EntryInvalid) do
        user.save!
      end

      user.sn = "Surname"
      assert(user.save)
      user.sn = "Surname2"
      assert_nothing_raised {user.save!}
    end
  end

  def test_reload
    make_temporary_user do |user, password|
      sn = user.sn
      new_sn = "New #{sn}"
      user.sn = new_sn
      assert_equal(new_sn, user.sn)
      user.reload
      assert_equal(sn, user.sn)
    end
  end

  def test_have_attribute?
    make_temporary_user do |user, password|
      assert(user.have_attribute?(:cn))
      assert(user.have_attribute?(:commonName))
      assert(user.have_attribute?(:common_name))
      assert(!user.have_attribute?(:commonname))
      assert(!user.have_attribute?(:COMMONNAME))

      assert(!user.have_attribute?(:unknown_attribute))
    end
  end

  def test_attribute_present?
    make_temporary_user do |user, password|
      assert(user.attribute_present?(:sn))
      user.sn = nil
      assert(!user.attribute_present?(:sn))
      user.sn = "Surname"
      assert(user.attribute_present?(:sn))
      user.sn = [nil]
      assert(!user.attribute_present?(:sn))
    end
  end

  def test_update_all
    make_temporary_user do |user, password|
      make_temporary_user do |user2, password|
        user2_cn = user2.cn
        new_cn = "New #{user.cn}"
        @user_class.update_all({:cn => new_cn}, user.uid)
        assert_equal(new_cn, @user_class.find(user.uid).cn)
        assert_equal(user2_cn, @user_class.find(user2.uid).cn)

        new_sn = "New SN"
        @user_class.update_all({:sn => [new_sn]})
        assert_equal(new_sn, @user_class.find(user.uid).sn)
        assert_equal(new_sn, @user_class.find(user2.uid).sn)

        new_sn2 = "New SN2"
        @user_class.update_all({:sn => [new_sn2]}, user2.uid)
        assert_equal(new_sn, @user_class.find(user.uid).sn)
        assert_equal(new_sn2, @user_class.find(user2.uid).sn)
      end
    end
  end

  def test_update
    make_temporary_user do |user, password|
      new_cn = "New #{user.cn}"
      new_user = @user_class.update(user.dn, {:cn => new_cn})
      assert_equal(new_cn, new_user.cn)

      make_temporary_user do |user2, password|
        new_sns = ["New SN1", "New SN2"]
        new_cn2 = "New #{user2.cn}"
        new_user, new_user2 = @user_class.update([user.dn, user2.dn],
                                                 [{:sn => new_sns[0]},
                                                  {:sn => new_sns[1],
                                                   :cn => new_cn2}])
        assert_equal(new_sns, [new_user.sn, new_user2.sn])
        assert_equal(new_cn2, new_user2.cn)
      end
    end
  end

  def test_exists
    assert(!@user_class.exists?("unknown-user"))
    assert(!@user_class.exists?("uid=unknown-user,#{@user_class.base}"))
    make_temporary_user do |user, password|
      assert(@user_class.exists?(user.dn))
      assert(@user_class.exists?("uid=#{user.uid}"))
      assert(@user_class.exists?(user.uid))
      user.destroy
      assert(!@user_class.exists?(user.dn))
      assert(!@user_class.exists?("uid=#{user.uid}"))
      assert(!@user_class.exists?(user.uid))
    end
  end
end
