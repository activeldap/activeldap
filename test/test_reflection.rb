require 'al-test-utils'

class ReflectionTest < Test::Unit::TestCase
  include AlTestUtils

  priority :must

  priority :normal
  def test_base_class
    assert_equal(ActiveLdap::Base, ActiveLdap::Base.base_class)
    assert_equal(@user_class, @user_class.base_class)
    sub_user_class = Class.new(@user_class)
    assert_equal(@user_class, sub_user_class.base_class)
  end

  def test_respond_to?
    make_temporary_user do |user, password|
      attributes = user.must + user.may
      _wrap_assertion do
        attributes.each do |name|
          assert(user.respond_to?(name), name)
          assert(user.respond_to?("#{name}="), "#{name}=")
          assert(user.respond_to?("#{name}?"), "#{name}?")
          assert(user.respond_to?("#{name}_before_type_cast"),
                 "#{name}_before_type_cast")
        end
      end

      user.replace_class(user.class.required_classes)
      new_attributes = collect_attributes(user.class.required_classes)

      _wrap_assertion do
        assert_not_equal([], new_attributes)
        new_attributes.each do |name|
          assert(user.respond_to?(name), name)
          assert(user.respond_to?("#{name}="), "#{name}=")
          assert(user.respond_to?("#{name}?"), "#{name}?")
          assert(user.respond_to?("#{name}_before_type_cast"),
                 "#{name}_before_type_cast")
        end

        remained_attributes = (attributes - new_attributes)
        assert_not_equal([], remained_attributes)
        remained_attributes.each do |name|
          assert(!user.respond_to?(name), name)
          assert(!user.respond_to?("#{name}="), "#{name}=")
          assert(!user.respond_to?("#{name}?"), "#{name}?")
          assert(!user.respond_to?("#{name}_before_type_cast"),
                 "#{name}_before_type_cast")
        end
      end
    end
  end

  def test_methods
    make_temporary_user do |user, password|
      assert_equal(user.methods.uniq.size, user.methods.size)
      assert_equal(user.methods(false).uniq.size, user.methods(false).size)
    end

    make_temporary_user do |user, password|
      attributes = user.must + user.may - ["objectClass"]
      assert_equal(["x500uniqueIdentifier"], attributes - user.methods)
      assert_equal(["x500uniqueIdentifier"], attributes - user.methods(false))

      assert_methods_with_only_required_classes(user, attributes)
    end

    make_temporary_user do |user, password|
      user.remove_class("inetOrgPerson")
      attributes = user.must + user.may - ["objectClass"]
      assert_equal([], attributes - user.methods)
      assert_equal([], attributes - user.methods(false))

      assert_methods_with_only_required_classes(user, attributes)
    end

    make_temporary_user do |user, password|
      attributes = user.must + user.may - ["objectClass"]
      attributes = attributes.collect {|x| x.downcase}
      assert_equal([], attributes - user.methods)
      assert_equal([], attributes - user.methods(false))

      normalize_attributes_list = Proc.new do |*attributes_list|
        attributes_list.collect do |attrs|
          attrs.collect {|x| x.downcase}
        end
      end
      assert_methods_with_only_required_classes(user, attributes,
                                                &normalize_attributes_list)
    end

    make_temporary_user do |user, password|
      attributes = user.must + user.may - ["objectClass"]
      attributes = attributes.collect do |x|
        ActiveLdap::Base.to_rubyish_name(x)
      end
      assert_equal(["x500unique_identifier"], attributes - user.methods)
      assert_equal(["x500unique_identifier"], attributes - user.methods(false))

      normalize_attributes_list = Proc.new do |*attributes_list|
        attributes_list.collect do |attrs|
          attrs.collect {|x| ActiveLdap::Base.to_rubyish_name(x)}
        end
      end
      assert_methods_with_only_required_classes(user, attributes,
                                                &normalize_attributes_list)
    end

    make_temporary_user do |user, password|
      user.remove_class("inetOrgPerson")
      attributes = user.must + user.may - ["objectClass"]
      attributes = attributes.collect do |x|
        ActiveLdap::Base.to_rubyish_name(x)
      end
      assert_equal([], attributes - user.methods)
      assert_equal([], attributes - user.methods(false))

      normalize_attributes_list = Proc.new do |*attributes_list|
        attributes_list.collect do |attrs|
          attrs.collect {|x| ActiveLdap::Base.to_rubyish_name(x)}
        end
      end
      assert_methods_with_only_required_classes(user, attributes,
                                                &normalize_attributes_list)
    end
  end

  def test_attribute_names
    make_temporary_user do |user, password|
      attributes = collect_attributes(user.classes)
      assert_equal([], attributes.uniq - user.attribute_names)
      assert_equal([], user.attribute_names - attributes.uniq)
    end
  end

  def assert_methods_with_only_required_classes(object, attributes)
    old_classes = (object.classes - object.class.required_classes).uniq
    old_attributes = collect_attributes(old_classes, false).uniq.sort
    required_attributes = collect_attributes(object.class.required_classes,
                                             false).uniq.sort
    if block_given?
      old_attributes, required_attributes =
        yield(old_attributes, required_attributes)
    end

    object.replace_class(object.class.required_classes)

    assert_equal([],
                 old_attributes -
                   (attributes - object.methods - required_attributes) -
                    required_attributes)
    assert_equal([],
                 old_attributes -
                   (attributes - object.methods(false) - required_attributes) -
                   required_attributes)
  end

  def collect_attributes(object_classes, with_aliases=true)
    attributes = []
    object_classes.each do |object_class|
      attrs = ActiveLdap::Base.schema.class_attributes(object_class)
      if with_aliases
        (attrs[:must] + attrs[:may]).each do |name|
          attributes.concat(ActiveLdap::Base.schema.attribute_aliases(name))
        end
      else
        attributes.concat(attrs[:must] + attrs[:may])
      end
    end
    attributes
  end
end
