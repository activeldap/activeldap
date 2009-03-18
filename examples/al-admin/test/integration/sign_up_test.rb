require 'test_helper'

class SignUpTest < ActionController::IntegrationTest
  include LdapTestHelper
  fixtures :all

  def setup
    setup_ldap_data
  end

  def teardown
    teardown_ldap_data
  end

  def test_sign_up
    visit("/")
    click_link("Sign up")

    fill_in("Login", :with => "test-user")
    fill_in("Password", :with => "test password")
    fill_in("Confirm Password", :with => "test password")
    fill_in("user[sn]", :with => "ser")
    assert_difference("User.count", 1) do
      assert_difference("LdapUser.count", 1) do
        click_button("Sign up")
      end
    end
  end

  def test_sign_up_failure
    visit("/")
    click_link("Sign up")

    fill_in("Login", :with => "test-user")
    fill_in("Password", :with => "test password")
    fill_in("Confirm Password", :with => "test password")
    assert_no_difference("User.count") do
      assert_no_difference("LdapUser.count") do
        click_button("Sign up")
      end
    end
    assert_have_selector("div.fieldWithErrors input#user_sn")
  end
end
