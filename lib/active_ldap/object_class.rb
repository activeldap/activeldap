module ActiveLdap
  module ObjectClass
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
    end

    def add_class(*target_classes)
      replace_class((classes + target_classes.flatten).uniq)
    end

    def remove_class(*target_classes)
      new_classes = (classes - target_classes.flatten).uniq
      assert_object_classes(new_classes)
      set_attribute('objectClass', new_classes)
    end

    def replace_class(*target_classes)
      new_classes = target_classes.flatten.uniq
      assert_object_classes(new_classes)
      set_attribute('objectClass', new_classes)
    end

    def classes
      (get_attribute('objectClass', true) || []).dup
    end

    private
    def assert_object_classes(new_classes)
      assert_valid_object_class_value_type(new_classes)
      assert_valid_object_class_value(new_classes)
      assert_have_all_required_classes(new_classes)
    end

    def assert_valid_object_class_value_type(new_classes)
      invalid_classes = new_classes.reject do |new_class|
        new_class.is_a?(String)
      end
      unless invalid_classes.empty?
        message = "Value in objectClass array is not a String"
        invalid_classes_info = invalid_classes.collect do |invalid_class|
          "#{invalid_class.class}:#{invalid_class.inspect}"
        end.join(", ")
        raise TypeError,  "#{message}: #{invalid_classes_info}"
      end
    end

    def assert_valid_object_class_value(new_classes)
      invalid_classes = new_classes.reject do |new_class|
        schema.exist_name?("objectClasses", new_class)
      end
      unless invalid_classes.empty?
        message = "unknown objectClass to LDAP server"
        message = "#{message}: #{invalid_classes.join(', ')}"
        raise ObjectClassError, message
      end
    end

    def assert_have_all_required_classes(new_classes)
      required_classes = self.class.required_classes - new_classes
      unless required_classes.empty?
        raise RequiredObjectClassMissed,
                "Can't remove required objectClass: " +
                 required_classes.join(", ")
      end
    end
  end
end
