require 'al-test-utils'

class TestObjectClass < Test::Unit::TestCase
  include AlTestUtils

  priority :must

  priority :normal
  def test_case_insensitive_match
    assert_nothing_raised do
      @group_class.instantiate(["cn=test-group,#{@group_class.base}",
                                {
                                  :cn => "test-group",
                                  :objectClass => ["TOP", "posixgroup"],
                                }])
    end
  end

  def test_ensure_recommended_classes
    make_temporary_group do |group|
      added_class = "labeledURIObject"

      assert_equal([], group.class.recommended_classes)
      group.class.recommended_classes += [added_class]
      assert_equal([added_class], group.class.recommended_classes)

      assert_equal([added_class],
                   group.class.recommended_classes - group.classes)
      group.ensure_recommended_classes
      assert_equal([],
                   group.class.recommended_classes - group.classes)
    end
  end

  def test_unknown_object_class
    make_temporary_group do |group|
      assert_raises(ActiveLdap::ObjectClassError) do
        group.add_class("unknownObjectClass")
      end
    end
  end

  def test_remove_required_class
    make_temporary_group do |group|
      assert_raises(ActiveLdap::RequiredObjectClassMissed) do
        group.remove_class("posixGroup")
      end
    end
  end

  def test_invalid_object_class_value
    make_temporary_group do |group|
      assert_raises(TypeError) {group.add_class(:posixAccount)}
    end
  end
end
