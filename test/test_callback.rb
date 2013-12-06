require 'al-test-utils'

class TestCallback < Test::Unit::TestCase
  include AlTestUtils

  priority :must
  def test_new
    initialized_entries = []
    @group_class.instance_variable_set("@initialized_entries",
                                       initialized_entries)
    @group_class.module_eval do
      after_initialize "self.class.instance_variable_get('@initialized_entries') << self"
    end
    assert_equal([], initialized_entries)
    new_group = @group_class.new(:cn => "new-cn")
    assert_equal([new_group.cn].sort,
                 initialized_entries.collect {|g| g.cn}.sort)
  end

  priority :normal
  def test_find
    make_temporary_group do |group|
      found_entries = []
      initialized_entries = []
      @group_class.instance_variable_set("@found_entries", found_entries)
      @group_class.instance_variable_set("@initialized_entries",
                                         initialized_entries)
      @group_class.module_eval do
        after_find "self.class.instance_variable_get('@found_entries') << self"
        after_initialize "self.class.instance_variable_get('@initialized_entries') << self"
      end

      assert_equal([], found_entries)
      assert_equal([], initialized_entries)

      found_group = @group_class.find(group.dn)

      assert_equal([found_group.cn].sort, found_entries.collect {|g| g.cn}.sort)
      assert_equal([found_group.cn].sort,
                   initialized_entries.collect {|g| g.cn}.sort)
    end
  end
end
