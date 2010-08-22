# -*- coding: utf-8 -*-
require 'al-test-utils'

class TestValidation < Test::Unit::TestCase
  include AlTestUtils
  include ActiveLdap::Helper

  priority :must
  def test_rename_duplicated
    make_temporary_user(:simple => true) do |user1,|
      make_temporary_user(:simple => true) do |user2,|
        user1.id = user2.id
        assert_false(user1.save)

        format = la_('distinguishedName')
        format  << ' ' << _("is duplicated: %s")
        assert_equal([format % [user2.dn.to_s]],
                     user1.errors.full_messages)
      end
    end
  end

  priority :normal
  def test_not_show_binary_value
    make_temporary_user do |user,|
      user.user_certificate = nil
      user.jpeg_photo = "XXX"
      assert_not_predicate(user, :save)

      format = la_('jpegPhoto')
      format << ' '  << _("has invalid format: %s: required syntax: %s: %s")
      arguments = [_("<binary-value>"),
                   lsd_("1.3.6.1.4.1.1466.115.121.1.28"),
                   _("invalid JPEG format")]
      message = format % arguments
      assert_equal([message],
                   user.errors.full_messages)
    end
  end

  def test_validation_skip_attributes
    make_temporary_group do |group|
      group.gid_number = nil
      assert_raise(ActiveLdap::EntryInvalid) do
        group.save!
      end
      group.validation_skip_attributes << "gidNumber"
      assert_raise(ActiveLdap::RequiredAttributeMissed) do
        group.save!
      end
    end
  end

  def test_set_attributes_with_invalid_dn_attribute_value
    user = nil
    assert_nothing_raised do
      user = @user_class.new(:uid => "=", :cn => "#")
    end
    assert(!user.valid?)
  end

  def test_set_attribute_to_invalid_dn_attribute_value_object
    user = @user_class.new("=")
    assert_nothing_raised do
      user.uid_number = 11111
    end
    assert_equal(11111, user.uid_number)
  end

  def test_dn_validate_on_new
    user = @user_class.new("=")
    assert(!user.valid?)
    reason = _("attribute value is missing")
    invalid_format = _("%s is invalid distinguished name (DN): %s")
    invalid_message = invalid_format % ["uid==,#{user.class.base}", reason]
    format = la_('distinguishedName')
    format << ' ' << _("is invalid: %s")
    message = format % invalid_message
    assert_equal([message],
                 user.errors.full_messages.find_all {|m| /DN/ =~ m})
  end

  def test_dn_validate
    make_temporary_user do |user,|
      user.uid = "="
      assert(!user.valid?)
      reason = _("attribute value is missing")
      invalid_format = _("%s is invalid distinguished name (DN): %s")
      invalid_message = invalid_format % ["uid==,#{user.class.base}", reason]
      format = la_('distinguishedName')
      format << ' ' << _("is invalid: %s")
      message = format % invalid_message
      assert_equal([message], user.errors.full_messages)
    end
  end

  def test_not_validate_empty_string
    make_temporary_user do |user,|
      assert(user.valid?)
      user.uid_number = ""
      assert(!user.valid?)
      format = la_('uidNumber')
      format << ' ' << _("is required attribute by objectClass '%s'")
      blank_message = format % loc_("posixAccount")
      assert_equal([blank_message], user.errors.full_messages)
    end
  end

  def test_validate_excluded_classes
    make_temporary_user do |user,|
      assert(user.save)
      user.class.excluded_classes = ['person']
      assert(!user.save)
      format = la_("objectClass")
      format << ' ' << n_("has excluded value: %s",
                          "has excluded values: %s",
                          1)
      message = format % loc_("person")
      assert_equal([message], user.errors.full_messages)
    end
  end

  def test_valid_subtype_and_single_value
    make_temporary_user do |user, password|
      user.display_name = [{"lang-ja" => ["ユーザ"]},
                           {"lang-en" => "User"}]
      assert(user.save)

      user = user.class.find(user.dn)
      assert_equal([{"lang-ja" => "ユーザ"},
                    {"lang-en" => "User"}].sort_by {|hash| hash.keys.first},
                   user.display_name.sort_by {|hash| hash.keys.first})
    end
  end

  def test_invalid_subtype_and_single_value
    assert_invalid_display_name_value(["User1", "User2"],
                                      ["User1", "User2"])
    assert_invalid_display_name_value(["User3", "User4"],
                                      [{"lang-en" => ["User3", "User4"]}],
                                      {"lang-en" => ["User3", "User4"]}.inspect)
    assert_invalid_display_name_value(["U2", "U3"],
                                      [{"lang-ja" => ["User1"]},
                                       {"lang-en" => ["U2", "U3"]}],
                                      [{"lang-ja" => "User1"},
                                       {"lang-en" => ["U2", "U3"]}].inspect)
  end

  def test_validate_required_ldap_values
    make_temporary_user(:simple => true) do |user, password|
      assert(user.save)

      user.add_class("strongAuthenticationUser")
      user.user_certificate = nil
      assert(!user.save)
      assert(user.errors.invalid?(:userCertificate))
      assert_equal(1, user.errors.size)
    end
  end

  def test_syntax_validation
    make_temporary_user do |user, password|
      assert(user.save)

      user.see_also = "cn=test,dc=example,dc=com"
      assert(user.save)
    end

    assert_invalid_see_also_value("test", "test")
    assert_invalid_see_also_value("test-en",
                                  ["cn=test,dc=example,dc=com",
                                   {"lang-en-us" => "test-en"}],
                                  "lang-en-us")
    assert_invalid_see_also_value("test-ja-jp",
                                  ["cn=test,dc=example,dc=com",
                                   {"lang-ja-jp" =>
                                     ["cn=test-ja,dc=example,dc=com",
                                      "test-ja-jp"]}],
                                  "lang-ja-jp")
  end

  def test_duplicated_dn_creation
    assert(ou_class.new("YYY").save)
    ou = ou_class.new("YYY")
    assert(!ou.save)
    format = la_("distinguishedName")
    format << ' ' << _("is duplicated: %s")
    message = format % ou.dn
    assert_equal([message], ou.errors.full_messages)
  end

  def test_save!
    make_temporary_group do |group|
      group.description = ""

      assert_nothing_raised do
        group.save!
      end

      @group_class.validates_presence_of(:description)
      assert_raises(ActiveLdap::EntryInvalid) do
        group.save!
      end
    end
  end

  def test_validates_presence_of
    make_temporary_group do |group|
      assert_nothing_raised do
        group.description = ""
      end
      assert(group.valid?)
      assert_equal([], group.errors.to_a)

      @group_class.validates_presence_of(:description)
      assert(!group.valid?)
      assert(group.errors.invalid?(:description))
      assert_equal(1, group.errors.size)
    end
  end

  private
  def assert_invalid_value(name, formatted_value, syntax, reason, model, option)
    syntax_description = lsd_(syntax)
    assert_not_nil(syntax_description)
    params = [formatted_value, syntax_description, reason]
    params.unshift(option) if option
    localized_name = la_(name)
    format = localized_name << ' '
    if option
      format << _("(%s) has invalid format: %s: required syntax: %s: %s")
    else
      format << _("has invalid format: %s: required syntax: %s: %s")
    end
    message = format % params
    assert_equal([message], model.errors.full_messages)
  end

  def assert_invalid_see_also_value(invalid_value, value, option=nil)
    make_temporary_user do |user, password|
      assert(user.save)

      user.see_also = "cn=test,dc=example,dc=com"
      assert(user.save)

      user.see_also = value
      assert(!user.save)
      assert(user.errors.invalid?(:seeAlso))
      assert_equal(1, user.errors.size)

      reason_params = [invalid_value, _("attribute value is missing")]
      reason = _('%s is invalid distinguished name (DN): %s') % reason_params
      assert_invalid_value("seeAlso", value.inspect,
                           "1.3.6.1.4.1.1466.115.121.1.12",
                           reason, user, option)
    end
  end

  def assert_invalid_display_name_value(invalid_value, value,
                                        formatted_value=nil)
    make_temporary_user do |user, password|
      assert(user.save)

      user.display_name = value
      assert(!user.save)

      reason_params = [la_("displayName"), invalid_value.inspect]
      reason = _('Attribute %s can only have a single value: %s') % reason_params
      assert_invalid_value("displayName", formatted_value || value.inspect,
                           "1.3.6.1.4.1.1466.115.121.1.15",
                           reason, user, nil)
    end
  end
end
