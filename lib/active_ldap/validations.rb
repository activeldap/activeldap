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

        validate_on_create :validate_duplicated_dn_creation
        validate :validate_excluded_classes
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
    def validate_duplicated_dn_creation
      if id and exist?
        if ActiveLdap.get_text_supported?
          format = _("%{fn} is duplicated: %s")
        else
          format = _("is duplicated: %s")
        end
        errors.add("dn", format % dn)
      end
    end

    def validate_excluded_classes
      return if self.class.excluded_classes.empty?

      _schema = schema
      unexpected_classes = self.class.excluded_classes.collect do |name|
        _schema.object_class(name)
      end
      unexpected_classes -= classes.collect do |name|
        _schema.object_class(name)
      end
      return if unexpected_classes.empty?

      names = unexpected_classes.collect do |object_class|
        self.class.human_object_class_name(object_class)
      end
      if ActiveLdap.get_text_supported?
        format = n_("%{fn} has excluded value: %s",
                    "%{fn} has excluded values: %s",
                    names.size)
      else
        format = n_("has excluded value: %s",
                    "has excluded values: %s",
                    names.size)
      end
      errors.add("objectClass", format % names.join(', '))
    end

    # validate_required_ldap_values
    #
    # Basic validation:
    # - Verify that every 'MUST' specified in the schema has a value defined
    def validate_required_ldap_values
      _schema = nil
      # Make sure all MUST attributes have a value
      entry_attribute.object_classes.each do |object_class|
        object_class.must.each do |required_attribute|
          # Normalize to ensure we catch schema problems
          # needed?
          real_name = to_real_attribute_name(required_attribute.name, true)
          raise UnknownAttribute.new(required_attribute) if real_name.nil?

          value = @data[real_name] || []
          next unless self.class.blank_value?(value)

          _schema ||= schema
          aliases = required_attribute.aliases.collect do |name|
            self.class.human_attribute_name(name)
          end
          args = [self.class.human_object_class_name(object_class)]
          if ActiveLdap.get_text_supported?
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

    def validate_ldap_values
      entry_attribute.schemata.each do |name, attribute|
        value = self[name]
        next if value.nil?
        validate_ldap_value(attribute, name, value)
      end
    end

    def validate_ldap_value(attribute, name, value)
      failed_reason, option = attribute.validate(value)
      return if failed_reason.nil?
      params = [self.class.human_readable_format(value),
                self.class.human_syntax_description(attribute.syntax),
                failed_reason]
      if ActiveLdap.get_text_supported?
        if option
          format =
            _("%{fn} (%s) has invalid format: %s: required syntax: %s: %s")
        else
          format = _("%{fn} has invalid format: %s: required syntax: %s: %s")
        end
      else
        if option
          format = _("(%s) has invalid format: %s: required syntax: %s: %s")
        else
          format = _("has invalid format: %s: required syntax: %s: %s")
        end
      end
      params.unshift(option) if option
      errors.add(name, format % params)
    end
  end
end
