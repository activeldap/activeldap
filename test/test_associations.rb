require 'al-test-utils'

class TestAssociations < Test::Unit::TestCase
  include AlTestUtils

  priority :must
  def test_belongs_to_replace_with_string
    make_temporary_user do |user,|
      make_temporary_group do |group1|
        make_temporary_group do |group2|
          user.groups = [group1, group2]
          user.save!

          user.groups = [group2.cn]

          group1.reload
          group2.reload
          assert_equal([group2], user.groups.to_a)
          assert_equal([], group1.member_uid(true))
          assert_equal([user.id], group2.member_uid(true))
        end
      end
    end
  end

  priority :normal
  def test_has_many_of_self
    @user_class.has_many(:references,
                         :class_name => "User",
                         :primary_key => "dn",
                         :foreign_key => "seeAlso")
    @user_class.set_associated_class(:references, @user_class)
    make_temporary_user do |user1, password1|
      make_temporary_user(:see_also => user1.dn.to_s) do |user2, password2|
        make_temporary_user(:see_also => user2.dn.to_s) do |user3, password3|
          make_temporary_user(:see_also => user2.dn.to_s) do |user4, password4|
            make_temporary_user(:see_also => user1.dn.to_s) do |user5, password5|
              user1_references = user1.references.collect {|r| r.dn.to_s}
              user2_references = user2.references.collect {|r| r.dn.to_s}
              user1_expected_references = [user2, user5].collect {|r| r.dn.to_s}
              user2_expected_references = [user3, user4].collect {|r| r.dn.to_s}
              assert_equal(user1_expected_references, user1_references)
              assert_equal(user2_expected_references, user2_references)
            end
          end
        end
      end
    end
  end

  def test_belongs_to_add_with_string
    make_temporary_user do |user,|
      make_temporary_group do |group1|
        make_temporary_group do |group2|
          assert_equal([[], []],
                       [group1.members.collect(&:cn),
                        group2.members.collect(&:cn)])

          user.groups = [group1.cn, group2.cn]
          user.save!

          group1.reload
          group2.reload
          assert_equal([[user.cn], [user.cn]],
                       [group1.members.collect(&:cn),
                        group2.members.collect(&:cn)])
        end
      end
    end
  end

  def test_has_many_delete_required_attribute
    make_temporary_group do |group|
      make_temporary_user do |user,|
        user.primary_group = group
        assert_raise(ActiveLdap::RequiredAttributeMissed) do
          group.primary_members.delete(user)
        end
      end
    end
  end

  def test_to_xml
    make_temporary_user do |user,|
      make_temporary_group do |group1|
        make_temporary_group do |group2|
          user.groups = [group1, group2]
          assert_equal(<<-EOX, user.groups.to_xml(:root => "groups"))
<?xml version="1.0" encoding="UTF-8"?>
<groups type="array">
  <group>
    <dn>#{group1.dn}</dn>
    <cns type="array">
      <cn>#{group1.cn}</cn>
    </cns>
    <gidNumber>#{group1.gid_number}</gidNumber>
    <memberUids type="array">
      <memberUid>#{user.cn}</memberUid>
    </memberUids>
    <objectClasses type="array">
      <objectClass>posixGroup</objectClass>
    </objectClasses>
  </group>
  <group>
    <dn>#{group2.dn}</dn>
    <cns type="array">
      <cn>#{group2.cn}</cn>
    </cns>
    <gidNumber>#{group2.gid_number}</gidNumber>
    <memberUids type="array">
      <memberUid>#{user.cn}</memberUid>
    </memberUids>
    <objectClasses type="array">
      <objectClass>posixGroup</objectClass>
    </objectClasses>
  </group>
</groups>
EOX
        end
      end
    end
  end

  def test_belongs_to_with_invalid_dn_attribute_value
    make_temporary_user do |user,|
      make_temporary_group do |group|
        user.primary_group = group
        user.uid = "#"
        assert_nothing_raised do
          user.primary_group.reload
        end
      end
    end
  end

  def test_belongs_to_foreign_key_before_1_1_0
    ActiveSupport::Deprecation.silence do
      @group_class.belongs_to :related_users, :many => "seeAlso",
                              :foreign_key => "dn"
    end
    @group_class.set_associated_class(:related_users, @user_class)
    make_temporary_user do |user,|
      make_temporary_group do |group|
        user.see_also = group.dn
        user.save!

        group = @group_class.find(group.id)
        assert_equal([user.dn], group.related_users.collect(&:dn))
      end
    end
  end

  def test_has_many_wrap_with_nonexistent_entry
    @user_class.has_many :references, :wrap => "seeAlso", :primary_key => "dn"
    @user_class.set_associated_class(:references, @group_class)
    @group_class.belongs_to :related_users, :many => "seeAlso",
                            :primary_key => "dn"
    @group_class.set_associated_class(:related_users, @user_class)
    make_temporary_user do |user,|
      make_temporary_group do |group1|
        make_temporary_group do |group2|
          user.references = [group1, group2]
          group3_dn = group2.dn.to_s.sub(/cn=(.*?),/, "cn=\\1-nonexistent,")
          user.see_also += [group3_dn]
          user.save!

          group3_dn = dn(group3_dn)
          user = @user_class.find(user.dn)
          assert_equal([group1.dn, group2.dn, group3_dn],
                       user.see_also)
          assert_equal([group1.dn, group2.dn, group3_dn],
                       user.references.collect(&:dn))
          assert_equal([group1.gid_number, group2.gid_number, nil],
                       user.references.collect(&:gid_number))
          assert_equal([false, false, true],
                       user.references.collect(&:new_entry?))
        end
      end
    end
  end

  def test_has_many_wrap_with_dn_value
    @user_class.has_many :references, :wrap => "seeAlso", :primary_key => "dn"
    @user_class.set_associated_class(:references, @group_class)
    @group_class.belongs_to :related_users, :many => "seeAlso",
                            :primary_key => "dn"
    @group_class.set_associated_class(:related_users, @user_class)
    make_temporary_user do |user,|
      make_temporary_group do |group1|
        make_temporary_group do |group2|
          make_temporary_group do |group3|
            entries = [user, group1, group2, group3]

            user.references << group1
            user, group1, group2, group3 = reload_entries(*entries)
            assert_references([[group1]], [user])
            assert_related_users([user], group1)
            assert_related_users([], group2)
            assert_related_users([], group3)

            user.references = [group2, group3]
            user, group1, group2, group3 = reload_entries(*entries)
            assert_references([[group2, group3]], [user])
            assert_related_users([], group1)
            assert_related_users([user], group2)
            assert_related_users([user], group3)

            user.references.delete(group2)
            user, group1, group2, group3 = reload_entries(*entries)
            assert_references([[group3]], [user])
            assert_related_users([], group1)
            assert_related_users([], group2)
            assert_related_users([user], group3)
          end
        end
      end
    end
  end

  def test_belongs_to_many_with_dn_value
    @user_class.has_many :references, :wrap => "seeAlso", :primary_key => "dn"
    @user_class.set_associated_class(:references, @group_class)
    @group_class.belongs_to :related_users, :many => "seeAlso",
                            :primary_key => "dn"
    @group_class.set_associated_class(:related_users, @user_class)
    make_temporary_group do |group|
      make_temporary_user do |user1,|
        make_temporary_user do |user2,|
          make_temporary_user do |user3,|
            entries = [group, user1, user2, user3]

            group.related_users = [user1, user2]
            group, user1, user2, user3 = reload_entries(*entries)
            assert_references([[group], [group], []],
                              [user1, user2, user3])
            assert_related_users([user1, user2], group)

            group.related_users << user3
            group, user1, user2, user3 = reload_entries(*entries)
            assert_references([[group], [group], [group]],
                              [user1, user2, user3])
            assert_related_users([user1, user2, user3], group)

            group.related_users.delete(user1)
            group, user1, user2, user3 = reload_entries(*entries)
            assert_references([[], [group], [group]],
                              [user1, user2, user3])
            assert_related_users([user2, user3], group)

            group.related_users = []
            group, user1, user2, user3 = reload_entries(*entries)
            assert_references([[], [], []],
                              [user1, user2, user3])
            assert_related_users([], group)
          end
        end
      end
    end
  end

  def test_belongs_to_many_with_dn_key
    @user_class.belongs_to :dn_groups, :many => "memberUid", :primary_key => "dn"
    @user_class.set_associated_class(:dn_groups, @group_class)
    @group_class.has_many :dn_members, :wrap => "memberUid", :primary_key => "dn"
    @group_class.set_associated_class(:dn_members, @user_class)
    make_temporary_group do |group|
      make_temporary_user do |user1,|
        make_temporary_user do |user2,|
          make_temporary_user do |user3,|
            entries = [group, user1, user2, user3]

            user1.dn_groups << group
            group, user1, user2, user3 = reload_entries(*entries)
            assert_dn_groups([[group], [], []], [user1, user2, user3])
            assert_dn_members([user1], group)

            user2.dn_groups = [group]
            group, user1, user2, user3 = reload_entries(*entries)
            assert_dn_groups([[group], [group], []], [user1, user2, user3])
            assert_dn_members([user1, user2], group)

            user1.dn_groups = []
            group, user1, user2, user3 = reload_entries(*entries)
            assert_dn_groups([[], [group], []], [user1, user2, user3])
            assert_dn_members([user2], group)

            user2.dn_groups.delete(group)
            group, user1, user2, user3 = reload_entries(*entries)
            assert_dn_groups([[], [], []], [user1, user2, user3])
            assert_dn_members([], group)
          end
        end
      end
    end
  end

  def test_belongs_to_many_delete
    make_temporary_group do |group1|
      make_temporary_group do |group2|
        make_temporary_user do |user,|
          user.update_attribute(:cn, "new #{user.cn}")

          user.groups = [group1, group2]
          assert_equal([group1.id, group2.id].sort,
                       user.groups.collect {|g| g.id}.sort)
          assert_equal([user.id].sort, group1.member_uid(true))
          assert_equal([user.id].sort, group2.member_uid(true))

          user.groups = []
          assert_equal([], user.groups.to_a)
          assert_equal([], group1.member_uid(true))
          assert_equal([], group2.member_uid(true))
        end
      end
    end
  end

  def test_belongs_to_before_save
    make_temporary_group do |group1|
      make_temporary_group do |group2|
        ensure_delete_group(group2.cn.succ) do |group3_name|
          group3 = @group_class.new(group3_name)
          group3.gid_number = group2.gid_number.succ
          make_temporary_user(:gid_number => group1.gid_number) do |user,|
            assert_equal(group1.gid_number, user.primary_group.gid_number)
            assert_equal(group1.gid_number, user.gid_number)

            user.primary_group = group2
            assert_equal(group2.gid_number, user.primary_group.gid_number)
            assert_equal(group2.gid_number, user.gid_number)

            user_in_ldap = @user_class.find(user.id)
            assert_equal(group1.gid_number,
                         user_in_ldap.primary_group.gid_number)
            assert_equal(group1.gid_number, user_in_ldap.gid_number)

            assert(group3.new_entry?)
            user.primary_group = group3
            assert_equal(group3.gid_number, user.primary_group.gid_number)
            assert_equal(group2.gid_number, user.gid_number)

            assert(user.save)
            assert_equal(group3.gid_number, user.gid_number)

            user_in_ldap = @user_class.find(user.id)
            assert(!user_in_ldap.primary_group.exists?)

            assert(group3.save)
            assert(user_in_ldap.primary_group.exists?)
            assert_equal(group3.gid_number,
                         user_in_ldap.primary_group.gid_number)
          end
        end
      end
    end
  end

  def test_extend
    mod = Module.new
    mod.__send__(:mattr_accessor, :called)
    mod.__send__(:define_method, :replace) do |entries|
      super(entries)
      mod.called = true
    end
    mod.called = false

    @group_class.send(:undef_method, :members, :members=, :__make_members)
    @group_class.has_many :members, :wrap => "memberUid",
                          :extend => mod
    @group_class.set_associated_class(:members, @user_class)

    make_temporary_group do |group|
      gid_number1 = group.gid_number.to_i + 1
      make_temporary_user(:gid_number => gid_number1) do |user1, password1|
        user1.update_attribute(:cn, "new #{user1.cn}")

        assert(!mod.called)
        group.members = [user1]
        assert(mod.called)
      end
    end
  end

  def test_has_many_wrap_assign
    make_temporary_group do |group|
      gid_number1 = group.gid_number.to_i + 1
      gid_number2 = group.gid_number.to_i + 2
      make_temporary_user(:gid_number => gid_number1) do |user1, password1|
        make_temporary_user(:gid_number => gid_number2) do |user2, password2|
          user1.update_attribute(:cn, "new #{user1.cn}")
          user2.update_attribute(:cn, "new #{user2.cn}")

          assert_equal([], group.members.to_a)
          assert_equal([], group.member_uid(true))

          assert_equal(gid_number1, user1.gid_number.to_i)
          assert_equal(gid_number2, user2.gid_number.to_i)
          group.members = [user1, user2]
          assert_equal([user1.uid, user2.uid].sort,
                       group.members.collect {|x| x.uid}.sort)
          assert_equal([user1.uid, user2.uid].sort, group.member_uid.sort)
          assert_equal(gid_number2, user2.gid_number.to_i)

          group.members = [user1]
          assert_equal([user1.uid].sort,
                       group.members.collect {|x| x.uid}.sort)
          assert_equal(user1.uid, group.member_uid)
          assert_equal(gid_number1, user1.gid_number.to_i)
        end
      end
    end
  end

  def test_has_many_wrap_assign_new_entry
    make_temporary_user do |user1, |
      make_temporary_user do |user2, |
        ensure_delete_group('test_new_group') do |cn|
          group = @group_class.new(:cn => cn, :gid_number => default_gid)

          assert_equal([], group.members.to_a)
          assert_equal([], group.member_uid(true))

          group.members = [user1, user2]

          assert group.new_entry?
          assert_equal([user1.uid, user2.uid].sort, group.members.map {|x| x.uid }.sort)
          assert_equal([user1.uid, user2.uid].sort, group.member_uid(true).sort)

          group.members = [user2]

          assert group.new_entry?
          assert_equal([user2.uid], group.members.map {|x| x.uid })
          assert_equal(user2.uid, group.member_uid)

          group.members << user1

          assert group.new_entry?
          assert_equal([user1.uid, user2.uid].sort, group.members.map {|x| x.uid }.sort)
          assert_equal([user1.uid, user2.uid].sort, group.member_uid.sort)

          assert(group.save)

          group = @group_class.find(cn)
          assert_equal([user1.uid, user2.uid].sort, group.members.map {|x| x.uid }.sort)
          assert_equal([user1.uid, user2.uid].sort, group.member_uid.sort)
        end
      end
    end
  end

  def test_has_many_validation
    group_class = Class.new(ActiveLdap::Base)
    group_class.ldap_mapping :prefix => "ou=Groups",
                             :scope => :sub,
                             :classes => ["posixGroup"]
    assert_raises(ArgumentError) do
      group_class.has_many :users, :unknown_name => "value"
    end

    mod = Module.new
    assert_nothing_raised do
      group_class.has_many :users, :class_name => "User"
      group_class.has_many :members, :class => @user_class, :wrap => "memberUid",
                           :extend => mod
      group_class.has_many :primary_members, :class => @user_class,
                           :primary_key => "gidNumber",
                           :foreign_key => "gidNumber",
                           :extend => mod
    end
  end

  def test_belongs_to_validation
    user_class = Class.new(ActiveLdap::Base)
    user_class.ldap_mapping :dn_attribute => "uid",
                            :prefix => "ou=Users",
                            :scope => :sub,
                            :classes => ["posixAccount", "person"]
    assert_raises(ArgumentError) do
      user_class.belongs_to :groups, :unknown_name => "value"
    end

    mod = Module.new
    assert_nothing_raised do
      user_class.belongs_to :string_groups, :class_name => "Group"
      user_class.belongs_to :groups, :class => @group_class,
                            :many => "memberUid",
                            :extend => mod
      user_class.belongs_to :primary_group, :class => @group_class,
                            :foreign_key => "gidNumber",
                            :primary_key => "gidNumber",
                            :extend => mod
    end
  end

  def test_has_many_assign
    make_temporary_group do |group|
      gid_number1 = group.gid_number.to_i + 1
      gid_number2 = group.gid_number.to_i + 2
      make_temporary_user(:gid_number => gid_number1) do |user1, password1|
        make_temporary_user(:gid_number => gid_number2) do |user2, password2|
          assert_equal(gid_number1, user1.gid_number.to_i)
          group.primary_members = [user1]
          assert_equal([user1.uid].sort,
                       group.primary_members.collect {|x| x.uid}.sort)
          assert_equal(group.gid_number, user1.gid_number)

          assert_equal(gid_number2, user2.gid_number.to_i)
          group.primary_members = [user1, user2]
          assert_equal([user1.uid, user2.uid].sort,
                       group.primary_members.collect {|x| x.uid}.sort)
          assert_equal(group.gid_number, user2.gid_number)


          assert_raises(ActiveLdap::RequiredAttributeMissed) do
            group.primary_members = []
          end

          assert_raises(ActiveLdap::RequiredAttributeMissed) do
            group.primary_members = [user1]
          end

          assert_raises(ActiveLdap::RequiredAttributeMissed) do
            group.primary_members = [user2]
          end

          assert_nothing_raised do
            group.primary_members = [user1, user2]
          end
        end
      end
    end
  end

  def test_belongs_to_many
    make_temporary_group do |group1|
      make_temporary_group do |group2|
        make_temporary_user do |user,|
          user.update_attribute(:cn, "new #{user.cn}")

          assert_equal([], user.groups.to_a)
          assert_equal([], group1.member_uid(true))
          assert_equal([], group2.member_uid(true))

          user.groups << group1
          assert_equal([group1.id].sort, user.groups.collect {|g| g.id}.sort)
          assert_equal([user.id].sort, group1.member_uid(true))
          assert_equal([].sort, group2.member_uid(true))

          user.groups << group2
          assert_equal([group1.id, group2.id].sort,
                       user.groups.collect {|g| g.id}.sort)
          assert_equal([user.id].sort, group1.member_uid(true))
          assert_equal([user.id].sort, group2.member_uid(true))
        end
      end
    end
  end

  def test_belongs_to_many_non_exist
    make_temporary_group do |group|
      ensure_delete_user("temp-user1") do |user1,|
        options = {:uid => "temp-user2", :gid_number => group.gid_number.succ}
        make_temporary_user(options) do |user2,|
          ensure_delete_user("temp-user3") do |user3,|
            group.members << user2
            group.member_uid = [user1, group.member_uid, user3]
            assert(group.save)
            group.members.reload
            assert_equal([user1, user2.id, user3],
                         group.members.collect {|g| g.id})
            assert_equal([true, false, true],
                         group.members.collect {|g| g.new_entry?})
          end
        end
      end
    end
  end

  def test_belongs_to
    make_temporary_group do |group|
      gid_number = group.gid_number.to_i + 1
      make_temporary_user(:gid_number => group.gid_number) do |user_in_group,|
        make_temporary_user(:gid_number => gid_number) do |user_not_in_group,|
          assert(user_in_group.primary_group.reload)
          assert(user_in_group.primary_group.loaded?)
          assert_equal(group.gid_number, user_in_group.gid_number)
          assert_equal(group.gid_number, user_in_group.primary_group.gid_number)


          assert(!user_not_in_group.primary_group.loaded?)

          assert_equal(gid_number, user_not_in_group.gid_number.to_i)
          assert_not_equal(group.gid_number, user_not_in_group.gid_number)

          user_not_in_group.primary_group = group
          assert(user_not_in_group.primary_group.loaded?)
          assert(user_not_in_group.primary_group.updated?)
          assert_equal(group.gid_number, user_not_in_group.gid_number)
          assert_equal(group.gid_number,
                       user_not_in_group.primary_group.gid_number)
          assert_not_equal(gid_number, user_not_in_group.gid_number.to_i)

          assert_equal(group.gid_number, user_in_group.gid_number)
          assert_equal(group.gid_number, user_in_group.primary_group.gid_number)
        end
      end
    end
  end

  def test_has_many_wrap
    make_temporary_group do |group|
      gid_number1 = group.gid_number.to_i + 1
      gid_number2 = group.gid_number.to_i + 2
      make_temporary_user(:gid_number => gid_number1) do |user1, password1|
        make_temporary_user(:gid_number => gid_number2) do |user2, password2|
          user1.update_attribute(:cn, "new #{user1.cn}")
          user2.update_attribute(:cn, "new #{user2.cn}")

          assert_equal([], group.members.to_a)
          assert_equal([], group.member_uid(true))

          assert_equal(gid_number1, user1.gid_number.to_i)
          group.members << user1
          assert_equal([user1.uid].sort,
                       group.members.collect {|x| x.uid}.sort)
          assert_equal(user1.uid, group.member_uid)
          assert_equal(gid_number1, user1.gid_number.to_i)

          assert_equal(gid_number2, user2.gid_number.to_i)
          group.members << user2
          assert_equal([user1.uid, user2.uid].sort,
                       group.members.collect {|x| x.uid}.sort)
          assert_equal([user1.uid, user2.uid].sort, group.member_uid.sort)
          assert_equal(gid_number2, user2.gid_number.to_i)
        end
      end
    end
  end

  def test_has_many
    make_temporary_group do |group|
      gid_number1 = group.gid_number.to_i + 1
      gid_number2 = group.gid_number.to_i + 2
      make_temporary_user(:gid_number => gid_number1) do |user1, password1|
        make_temporary_user(:gid_number => gid_number2) do |user2, password2|
          assert_equal([], group.primary_members.to_a)

          assert_equal(gid_number1, user1.gid_number.to_i)
          group.primary_members << user1
          assert_equal([user1.uid].sort,
                       group.primary_members.collect {|x| x.uid}.sort)
          assert_equal(group.gid_number, user1.gid_number)

          assert_equal(gid_number2, user2.gid_number.to_i)
          group.primary_members << user2
          assert_equal([user1.uid, user2.uid].sort,
                       group.primary_members.collect {|x| x.uid}.sort)
          assert_equal(group.gid_number, user2.gid_number)
        end
      end
    end
  end

  private
  def reload_entries(*entries)
    entries.collect do |entry|
      entry.class.find(entry[entry.dn_attribute])
    end
  end

  def assert_groups_relation(expected_groups_values, entries, relation_name)
    expected_groups_values = expected_groups_values.collect do |groups|
      groups.collect(&:cn).sort
    end
    actual_groups_values = entries.collect do |entry|
      entry.send(relation_name).collect(&:cn).sort
    end
    assert_equal(expected_groups_values, actual_groups_values)
  end

  def assert_users_relation(expected_users, group, relation_name)
    assert_equal(expected_users.collect(&:cn).sort,
                 group.send(relation_name).collect(&:cn).sort)
  end

  def assert_references(expected_groups_values, users)
    assert_groups_relation(expected_groups_values, users, :references)
  end

  def assert_related_users(expected_users, group)
    assert_users_relation(expected_users, group, :related_users)
  end

  def assert_dn_groups(expected_groups_values, users)
    assert_groups_relation(expected_groups_values, users, :dn_groups)
  end

  def assert_dn_members(expected_users, group)
    assert_users_relation(expected_users, group, :dn_members)
  end
end
