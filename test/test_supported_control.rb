# -*- coding: utf-8 -*-

require 'al-test-utils'

class TestSupportedControl < Test::Unit::TestCase
  def supported_control(controls)
    ActiveLdap::SupportedControl.new(controls)
  end

  class TestPagedResults < self
    def paged_results?(controls)
      supported_control(controls).paged_results?
    end

    def test_true
      assert_true(paged_results?(ActiveLdap::LdapControls::PAGED_RESULTS))
    end

    def test_false
      assert_false(paged_results?(ActiveLdap::LdapControls::ASSERTION))
    end
  end
end
