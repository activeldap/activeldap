# -*- coding: utf-8 -*-

require 'al-test-utils'

class TestAttributes < Test::Unit::TestCase
  include AlTestUtils

  priority :must

  priority :normal
  def test_to_real_attribute_name
    user = @user_class.new("user")
    assert_equal("objectClass",
                 user.__send__(:to_real_attribute_name, "objectclass"))
    assert_equal("objectClass",
                 user.__send__(:to_real_attribute_name, "objectclass", true))
    assert_nil(user.__send__(:to_real_attribute_name, "objectclass", false))
  end

  def test_normalize_attribute
    assert_normalize_attribute(["usercertificate", [{"binary" => []}]],
                               "userCertificate",
                               [])
    assert_normalize_attribute(["usercertificate", [{"binary" => []}]],
                               "userCertificate",
                               nil)
    assert_normalize_attribute(["usercertificate",
                                [{"binary" => "BINARY DATA"}]],
                               "userCertificate",
                               "BINARY DATA")
    assert_normalize_attribute(["usercertificate",
                                [{"binary" => ["BINARY DATA"]}]],
                               "userCertificate",
                               {"binary" => ["BINARY DATA"]})
  end

  def test_unnormalize_attribute
    assert_unnormalize_attribute({"sn" => ["Surname"]},
                                 "sn",
                                 ["Surname"])
    assert_unnormalize_attribute({"userCertificate;binary" => []},
                                 "userCertificate",
                                 [{"binary" => []}])
    assert_unnormalize_attribute({"userCertificate;binary" => ["BINARY DATA"]},
                                 "userCertificate",
                                 [{"binary" => ["BINARY DATA"]}])
    assert_unnormalize_attribute({
                                   "sn" => ["Yamada"],
                                   "sn;lang-ja" => ["山田"],
                                   "sn;lang-ja;phonetic" => ["やまだ"]
                                 },
                                 "sn",
                                 ["Yamada",
                                  {"lang-ja" => ["山田",
                                                 {"phonetic" => ["やまだ"]}]}])
  end

  private
  def assert_normalize_attribute(expected, name, value)
    assert_equal(expected, ActiveLdap::Base.normalize_attribute(name, value))
  end

  def assert_unnormalize_attribute(expected, name, value)
    assert_equal(expected, ActiveLdap::Base.unnormalize_attribute(name, value))
  end

  class TestBlankValue < self
    private
    def assert_blank_value(value)
      assert_true(ActiveLdap::Base.blank_value?(value),
                  "value: <#{value.inspect}>")
    end

    def assert_not_blank_value(value)
      assert_false(ActiveLdap::Base.blank_value?(value),
                   "value: <#{value.inspect}>")
    end

    class TestHash < self
      def test_empty
        assert_blank_value({})
      end

      def test_have_elements
        assert_not_blank_value({"name" => "Taro", "age" => 29})
      end

      def test_have_blank_element
        assert_not_blank_value({"name" => nil, "age" => 29})
      end

      def test_all_blank_elements
        assert_blank_value({"name" => nil, "age" => nil})
      end
    end

    class TestArray < self
      def test_empty
        assert_blank_value([])
      end

      def test_have_elements
        assert_not_blank_value(["Taro", "Jiro"])
      end

      def test_have_blank_element
        assert_not_blank_value(["Taro", nil])
      end

      def test_all_blank_elements
        assert_blank_value([nil, nil])
      end
    end

    class TestString < self
      def test_empty
        assert_blank_value("")
      end

      def test_only_spaces
        assert_blank_value(" \t\n")
      end

      def test_have_non_spaces
        assert_not_blank_value("Taro")
      end
    end

    class TestBoolean < self
      def test_true
        assert_not_blank_value(true)
      end

      def test_false
        assert_not_blank_value(true)
      end
    end
  end

  class TestMassAssignment < self
    def test_forbid
      attributes = {:cn => "Alice"}
      def attributes.permitted?
        false
      end
      assert_raise(ActiveModel::ForbiddenAttributesError) do
        @user_class.new(attributes)
      end
    end

    def test_permit
      attributes = {:cn => "Alice"}
      def attributes.permitted?
        true
      end
      alice = @user_class.new(attributes)
      assert_equal("Alice", alice.cn)
    end

    def test_forbid_object_class
      classes = @user_class.required_classes + ["inetOrgPerson"]
      user = @user_class.new(:uid => "XXX", :object_class => classes)
      assert_equal(["inetOrgPerson"],
                   user.classes -  @user_class.required_classes)

      user = @user_class.new(:uid => "XXX", :object_class => ['inetOrgPerson'])
      assert_equal(["inetOrgPerson"],
                   user.classes -  @user_class.required_classes)

      user = @user_class.new("XXX")
      assert_equal([], user.classes -  @user_class.required_classes)
      user.attributes = {:object_class => classes}
      assert_equal([], user.classes -  @user_class.required_classes)
    end

    def test_rename
      make_temporary_user(:simple => true) do |user,|
        assert_true(user.update_attributes(:id => "user2"))
        assert_equal("user2", user.id)
      end
    end
  end
end
