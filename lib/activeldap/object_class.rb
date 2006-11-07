module ActiveLDAP
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
      check_required_class(new_classes)
      set_attribute('objectClass', new_classes)
    end

    def replace_class(*target_classes)
      new_classes = target_classes.flatten.uniq
      check_required_class(new_classes)
      set_attribute('objectClass', new_classes)
    end

    def classes
      (get_attribute('objectClass', false) || []).dup
    end

    private
    def check_required_class(new_classes)
      required_classes = self.class.required_classes - new_classes
      unless required_classes.empty?
        raise RequiredObjectClassMissed,
                "Can't remove required objectClass: " +
                 required_classes.join(", ")
      end
    end
  end
end
