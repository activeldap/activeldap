# -*- coding: utf-8 -*-

require 'al-test-utils'

class TestPersistence < Test::Unit::TestCase
  include AlTestUtils

  class TestDestroy < self
    class TestClass < self
      def test_by_dn
        make_temporary_user do |user,|
          assert(@user_class.exists?(user.uid))
          @user_class.destroy(user.dn)
          assert(!@user_class.exists?(user.uid))
        end
      end

      def test_by_dn_value
        make_temporary_user do |user,|
          assert(@user_class.exists?(user.dn))
          @user_class.destroy(user.uid)
          assert(!@user_class.exists?(user.dn))
        end
      end

      def test_by_dn_attribute
        make_temporary_user do |user,|
          assert(@user_class.exists?(user.dn))
          @user_class.destroy("uid=#{user.uid}")
          assert(!@user_class.exists?(user.dn))
        end
      end

      def test_multiple
        make_temporary_user do |user1,|
          make_temporary_user do |user2,|
            make_temporary_user do |user3,|
              assert(@user_class.exists?(user1.uid))
              assert(@user_class.exists?(user2.uid))
              assert(@user_class.exists?(user3.uid))
              @user_class.destroy([user1.dn, user2.uid, "uid=#{user3.uid}"])
              assert(!@user_class.exists?(user1.uid))
              assert(!@user_class.exists?(user2.uid))
              assert(!@user_class.exists?(user3.uid))
            end
          end
        end
      end
    end

    class TestInstance < self
      def test_existence
        make_temporary_user do |user,|
          assert(@user_class.exists?(user.uid))
          user.destroy
          assert(!@user_class.exists?(user.uid))
        end
      end

      def test_frozen
        make_temporary_user do |user,|
          assert_false(user.frozen?)
          user.destroy
          assert_true(user.frozen?)
        end
      end
    end
  end

  class TestDelete < self
    class TestClass < self
      def test_by_dn
        make_temporary_user do |user,|
          assert(@user_class.exists?(user.uid))
          @user_class.delete(user.dn)
          assert(!@user_class.exists?(user.uid))
        end
      end

      def test_by_dn_value
        make_temporary_user do |user,|
          assert(@user_class.exists?(user.dn))
          @user_class.delete(user.uid)
          assert(!@user_class.exists?(user.dn))
        end
      end

      def test_by_dn_attribute
        make_temporary_user do |user,|
          assert(@user_class.exists?(user.dn))
          @user_class.delete("uid=#{user.uid}")
          assert(!@user_class.exists?(user.dn))
        end
      end

      def test_multiple
        make_temporary_user do |user1,|
          make_temporary_user do |user2,|
            make_temporary_user do |user3,|
              assert(@user_class.exists?(user1.uid))
              assert(@user_class.exists?(user2.uid))
              assert(@user_class.exists?(user3.uid))
              @user_class.delete([user1.dn, user2.uid, "uid=#{user3.uid}"])
              assert(!@user_class.exists?(user1.uid))
              assert(!@user_class.exists?(user2.uid))
              assert(!@user_class.exists?(user3.uid))
            end
          end
        end
      end
    end

    class TestInstance < self
      def test_existence
        make_temporary_user do |user,|
          assert(@user_class.exists?(user.uid))
          user.delete
          assert(!@user_class.exists?(user.uid))
        end
      end

      def test_frozen
        make_temporary_user do |user,|
          assert_false(user.frozen?)
          user.delete
          assert_true(user.frozen?)
        end
      end
    end
  end
end
