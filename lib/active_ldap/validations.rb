require 'active_record/validations'

module ActiveLdap
  module Validations
    def self.append_features(base)
      super

      base.class_eval do
        alias_method :new_record?, :new_entry?
        class << self
          alias_method :human_attribute_name_active_ldap,
                       :human_attribute_name
        end
        include ActiveRecord::Validations
        class << self
          alias_method :human_attribute_name,
                       :human_attribute_name_active_ldap
          unless method_defined?(:human_attribute_name_with_gettext)
            def human_attribute_name_with_gettext(attribute_key_name)
              s_("#{self}|#{attribute_key_name.humanize}")
            end
          end
        end

        # Workaround for GetText's ugly implementation
        begin
          instance_method(:save_without_validation)
        rescue NameError
          alias_method_chain :save, :validation
          alias_method_chain :save!, :validation
          alias_method_chain :update_attribute, :validation_skipping
        end

        validate :validate_required_ldap_values
        validate :validate_ldap_values

        class << self
          def evaluate_condition_with_active_ldap_support(condition, entry)
            evaluate_condition_without_active_ldap_support(condition, entry)
          rescue ActiveRecord::ActiveRecordError
            raise Error, $!.message
          end
          alias_method_chain :evaluate_condition, :active_ldap_support
        end

        def save_with_active_ldap_support!
          save_without_active_ldap_support!
        rescue ActiveRecord::RecordInvalid
          raise EntryInvalid, $!.message
        end
        alias_method_chain :save!, :active_ldap_support

        def valid?
          ensure_apply_object_class
          super
        end

        private
        def run_validations_with_active_ldap_support(validation_method)
          run_validations_without_active_ldap_support(validation_method)
        rescue ActiveRecord::ActiveRecordError
          raise Error, $!.message
        end
        alias_method_chain :run_validations, :active_ldap_support
      end
    end

    private
    # validate_required_ldap_values
    #
    # Basic validation:
    # - Verify that every 'MUST' specified in the schema has a value defined
    def validate_required_ldap_values
      # Make sure all MUST attributes have a value
      @object_classes.each do |object_class|
        object_class.must.each do |required_attribute|
          # Normalize to ensure we catch schema problems
          # needed?
          real_name = to_real_attribute_name(required_attribute.name, true)
          raise UnknownAttribute.new(required_attribute) if real_name.nil?
          # # Set default if it wasn't yet set.
          # @data[real_name] ||= [] # need?
          value = @data[real_name] || []
          # Check for missing requirements.
          if value.empty?
            _schema = schema
            aliases = required_attribute.aliases.collect do |name|
              self.class.human_attribute_name(name)
            end
            args = [self.class.human_object_class_name(object_class)]
            if ActiveLdap.get_text_support?
              if aliases.empty?
                format = _("%{fn} is required attribute by objectClass '%s'")
              else
                format = _("%{fn} is required attribute by objectClass " \
                           "'%s': aliases: %s")
                args << aliases.join(', ')
              end
            else
              if aliases.empty?
                format = "is required attribute by objectClass '%s'"
              else
                format = "is required attribute by objectClass '%s'" \
                         ": aliases: %s"
                args << aliases.join(', ')
              end
            end
            errors.add(real_name, format % args)
          end
        end
      end
    end

    def validate_ldap_values
      @attribute_schemata.each do |name, attribute|
        self[name, true].each do |value|
          unless attribute.valid?(value)
            params = [value, attribute.syntax_description]
            if ActiveLdap.get_text_support?
              format = _("%{fn} has invalid format: %s: required syntax: %s")
            else
              format = _("has invalid format: %s: required syntax: %s")
            end
            errors.add(name, format % params)
          end
        end
      end
    end
  end
end
