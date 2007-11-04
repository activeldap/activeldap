require 'al-test-utils'

class TestValidation < Test::Unit::TestCase
  include AlTestUtils
  include ActiveLdap::Helper

  priority :must
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

  priority :normal
  def test_duplicated_dn_creation
    assert(ou_class.new("YYY").save)
    ou = ou_class.new("YYY")
    assert(!ou.save)
    if ActiveLdap.get_text_supported?
      format = _("%{fn} is duplicated: %s") % {:fn => la_("DN")}
    else
      format = "Dn " + _("is duplicated: %s")
    end
    assert_equal([format % ou.dn], ou.errors.full_messages)
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
  def assert_invalid_see_also_value(invalid_value, value, option=nil)
    make_temporary_user do |user, password|
      assert(user.save)

      user.see_also = "cn=test,dc=example,dc=com"
      assert(user.save)

      user.see_also = value
      assert(!user.save)
      assert(user.errors.invalid?(:seeAlso))
      assert_equal(1, user.errors.size)

      syntax_description = lsd_("1.3.6.1.4.1.1466.115.121.1.12")
      assert_not_nil(syntax_description)
      reason_params = [invalid_value, _("attribute value is missing")]
      reason = _('%s is invalid distinguished name (DN): %s') % reason_params
      params = [invalid_value, syntax_description, reason]
      params.unshift(option) if option
      if ActiveLdap.get_text_supported?
        if option
          format =
            _("%{fn} (%s) has invalid format: %s: required syntax: %s: %s")
        else
          format = _("%{fn} has invalid format: %s: required syntax: %s: %s")
        end
        format = format % {:fn => la_("seeAlso")}
        assert_equal([format % params], user.errors.full_messages)
      else
        if option
          format = _("(%s) has invalid format: %s: required syntax: %s: %s")
        else
          format = _("has invalid format: %s: required syntax: %s: %s")
        end
        assert_equal(["seeAlso #{format % params}"], user.errors.full_messages)
      end
    end
  end
end
