module ActiveLdap
  module HumanReadable
    def self.included(base)
      super
      base.extend(ClassMethods)
    end

    module ClassMethods
      def human_attribute_name(attribute_or_name)
        msgid = human_attribute_name_msgid(attribute_or_name)
        msgid ||= human_attribute_name_with_gettext(attribute_or_name)
        s_(msgid)
      end

      def human_attribute_name_msgid(attribute_or_name)
        if attribute_or_name.is_a?(Schema::Attribute)
          name = attribute_or_name.name
        else
          attribute = schema.attribute(attribute_or_name)
          return nil if attribute.id.nil?
          if attribute.name == attribute_or_name or
              attribute.aliases.include?(attribute_or_name)
            name = attribute_or_name
          else
            return nil
          end
        end
        "LDAP|Attribute|#{name}"
      end

      def human_attribute_description(attribute_or_name)
        msgid = human_attribute_description_msgid(attribute_or_name)
        return nil if msgid.nil?
        s_(msgid)
      end

      def human_attribute_description_msgid(attribute_or_name)
        if attribute_or_name.is_a?(Schema::Attribute)
          attribute = attribute_or_name
        else
          attribute = schema.attribute(attribute_or_name)
          return nil if attribute.nil?
        end
        description = attribute.description
        return nil if description.nil?
        "LDAP|Description|Attribute|#{attribute.name}|#{description}"
      end

      def human_object_class_name(object_class_or_name)
        s_(human_object_class_name_msgid(object_class_or_name))
      end

      def human_object_class_name_msgid(object_class_or_name)
        if object_class_or_name.is_a?(Schema::ObjectClass)
          name = object_class_or_name.name
        else
          name = object_class_or_name
        end
        "LDAP|ObjectClass|#{name}"
      end

      def human_object_class_description(object_class_or_name)
        msgid = human_object_class_description_msgid(object_class_or_name)
        return nil if msgid.nil?
        s_(msgid)
      end

      def human_object_class_description_msgid(object_class_or_name)
        if object_class_or_name.is_a?(Schema::ObjectClass)
          object_class = object_class_or_name
        else
          object_class = schema.object_class(object_class_or_name)
          return nil if object_class.nil?
        end
        description = object_class.description
        return nil if description.nil?
        "LDAP|Description|ObjectClass|#{object_class.name}|#{description}"
      end

      def human_syntax_name(syntax_or_id)
        s_(human_syntax_name_msgid(syntax_or_id))
      end

      def human_syntax_name_msgid(syntax_or_id)
        if syntax_or_id.is_a?(Schema::Syntax)
          id = syntax_or_id.id
        else
          id = syntax_or_id
        end
        "LDAP|Syntax|#{id}"
      end

      def human_syntax_description(syntax_or_id)
        msgid = human_syntax_description_msgid(syntax_or_id)
        return nil if msgid.nil?
        s_(msgid)
      end

      def human_syntax_description_msgid(syntax_or_id)
        if syntax_or_id.is_a?(Schema::Syntax)
          syntax = syntax_or_id
        else
          syntax = schema.ldap_syntax(syntax_or_id)
          return nil if syntax.nil?
        end
        description = syntax.description
        return nil if description.nil?
        "LDAP|Description|Syntax|#{syntax.id}|#{description}"
      end
    end
  end
end
