require 'al-test-utils'

class ValidationTest < Test::Unit::TestCase
  include AlTestUtils

  priority :must
  def test_save!
    make_temporary_group do |group|
      group.description = ""

      assert_nothing_raised do
        group.save!
      end

      @group_class.validates_presence_of(:description)
      assert_raises(ActiveLDAP::EntryInvalid) do
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

  priority :normal
end
