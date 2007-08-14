require 'al-test-utils'

class TestCallback < Test::Unit::TestCase
  include AlTestUtils

  priority :must

  priority :normal
  def test_callback_after_find_and_after_initialize
    make_temporary_group do |group|
      found_entries = []
      initialized_entries = []
      @group_class.instance_variable_set("@found_entries", found_entries)
      @group_class.instance_variable_set("@initialized_entries",
                                         initialized_entries)
      @group_class.module_eval do
        define_method(:after_find) do
          self.class.instance_variable_get("@found_entries") << self
        end
        define_method(:after_initialize) do
          self.class.instance_variable_get("@initialized_entries") << self
        end
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
