# -*- coding: utf-8 -*-

require 'al-test-utils'

class TestEntry < Test::Unit::TestCase
  include AlTestUtils

  def test_all
    make_temporary_group do |group|
      make_temporary_user do |user, password|
        all_entries = [ActiveLdap::Base.base]
        all_entries += [user.dn, user.base]
        all_entries += [group.dn, group.base]
        all_entries += [@group_of_urls_class.base]
        assert_equal(all_entries.sort,
                     ActiveLdap::Entry.all.collect(&:dn).sort)
      end
    end
  end
end
