require 'al-test-utils'

class AssociationsTest < Test::Unit::TestCase
  include AlTestUtils

  priority :must
  def test_extend
    mod = Module.new
    mod.__send__(:mattr_accessor, :called)
    mod.__send__(:define_method, :replace) do |entries|
      super
      mod.called = true
    end
    mod.called = false

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
          assert_equal([user1.uid].sort, group.member_uid.sort)
          assert_equal(gid_number1, user1.gid_number.to_i)
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
      group_class.has_many :members, :class_name => "User"
    end

    mod = Module.new
    assert_nothing_raised do
      group_class.has_many :members, :class => "User", :wrap => "memberUid",
                           :extend => mod
      group_class.has_many :primary_members, :class => "User",
                           :foreign_key => "gidNumber",
                           :primary_key => "gidNumber",
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
      user_class.belongs_to :groups, :class_name => "Group"
    end

    mod = Module.new
    assert_nothing_raised do
      user_class.belongs_to :groups, :class => "Group", :many => "memberUid",
                            :extend => mod
      user_class.belongs_to :primary_group, :class => "Group",
                            :foreign_key => "gidNumber",
                            :primary_key => "gidNumber",
                            :extend => mod
    end
  end

  priority :normal
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
          assert_equal([user1.uid].sort, group.member_uid.sort)
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
end
