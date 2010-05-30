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
          alias_method :human_attribute_name_active_record,
                       :human_attribute_name
          alias_method :human_attribute_name,
                       :human_attribute_name_active_ldap
          unless method_defined?(:human_attribute_name_with_gettext)
            def human_attribute_name_with_gettext(attribute_key_name)
              s_("#{self}|#{attribute_key_name.humanize}")
            end
          end
        end

        class_local_attr_accessor true, :validation_skip_attributes
        remove_method :validation_skip_attributes
        self.validation_skip_attributes = []

        # Workaround for GetText's ugly implementation
        begin
          instance_method(:save_without_validation)
        rescue NameError
          alias_method_chain :save, :validation
          alias_method_chain :save!, :validation
          alias_method_chain :update_attribute, :validation_skipping
        end

        validate_on_create :validate_duplicated_dn_creation
        validate_on_update :validate_duplicated_dn_rename
        validate :validate_dn
        validate :validate_excluded_classes
        validate :validate_required_ldap_values
        validate :validate_ldap_values

        class << self
          if method_defined?(:evaluate_condition)
            def evaluate_condition_with_active_ldap_support(condition, entry)
              evaluate_condition_without_active_ldap_support(condition, entry)
            rescue ActiveRecord::ActiveRecordError
              raise Error, $!.message
            end
            alias_method_chain :evaluate_condition, :active_ldap_support
          end
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
        if private_method_defined?(:run_validations)
          alias_method_chain :run_validations, :active_ldap_support
        else
          alias_method(:run_callbacks_with_active_ldap_support,
                       :run_validations_with_active_ldap_support)
          alias_method_chain :run_callbacks, :active_ldap_support
          alias_method(:run_validations_without_active_ldap_support,
                       :run_callbacks_without_active_ldap_support)
        end
      end
    end

    def validation_skip_attributes
      @validation_skip_attributes ||= []
    end

    def validation_skip_attributes=(attributes)
      @validation_skip_attributes = attributes
    end

    private
    def validate_duplicated_dn_creation
      _dn = nil
      begin
        _dn = dn
      rescue DistinguishedNameInvalid, DistinguishedNameNotSetError
        return
      end
      if _dn and exist?
        format = _("%{fn} is duplicated: %s")
        unless ActiveLdap.get_text_supported?
          format = format.sub(/^%\{fn\} /, '')
        end
        errors.add("distinguishedName", format % _dn)
      end
    end

    def validate_duplicated_dn_rename
      _dn_attribute = dn_attribute_with_fallback
      original_dn_value = @ldap_data[_dn_attribute]
      current_dn_value = @data[_dn_attribute]
      return if original_dn_value == current_dn_value
      return if original_dn_value == [current_dn_value]

      _dn = nil
      begin
        _dn = dn
      rescue DistinguishedNameInvalid, DistinguishedNameNotSetError
        return
      end
      if _dn and exist?
        format = _("%{fn} is duplicated: %s")
        unless ActiveLdap.get_text_supported?
          format = format.sub(/^%\{fn\} /, '')
        end
        errors.add("distinguishedName", format % _dn)
      end
    end

    def validate_dn
      dn
    rescue DistinguishedNameInvalid
      format = _("%{fn} is invalid: %s")
      format = format.sub(/^%\{fn\} /, '') unless ActiveLdap.get_text_supported?
      errors.add("distinguishedName", format % $!.message)
    rescue DistinguishedNameNotSetError
      format = _("%{fn} isn't set: %s")
      format = format.sub(/^%\{fn\} /, '') unless ActiveLdap.get_text_supported?
      errors.add("distinguishedName", format % $!.message)
    end

    def validate_excluded_classes
      excluded_classes = self.class.excluded_classes
      return if excluded_classes.empty?

      _schema = schema
      _classes = classes.collect do |name|
        _schema.object_class(name)
      end
      unexpected_classes = excluded_classes.inject([]) do |classes, name|
        excluded_class = _schema.object_class(name)
        if _classes.include?(excluded_class)
          classes << excluded_class
        end
        classes
      end
      return if unexpected_classes.empty?

      names = unexpected_classes.collect do |object_class|
        self.class.human_object_class_name(object_class)
      end
      format = n_("%{fn} has excluded value: %s",
                  "%{fn} has excluded values: %s",
                  names.size)
      format = format.sub(/^%\{fn\} /, '') unless ActiveLdap.get_text_supported?
      errors.add("objectClass", format % names.join(", "))
    end

    # validate_required_ldap_values
    #
    # Basic validation:
    # - Verify that every 'MUST' specified in the schema has a value defined
    def validate_required_ldap_values
      _schema = nil
      @validation_skip_attributes ||= []
      _validation_skip_attributes =
        @validation_skip_attributes +
        (self.class.validation_skip_attributes || [])
      # Make sure all MUST attributes have a value
      entry_attribute.object_classes.each do |object_class|
        object_class.must.each do |required_attribute|
          # Normalize to ensure we catch schema problems
          # needed?
          real_name = to_real_attribute_name(required_attribute.name, true)
          raise UnknownAttribute.new(required_attribute) if real_name.nil?

          next if required_attribute.read_only?
          next if _validation_skip_attributes.include?(real_name)

          value = @data[real_name] || []
          next unless self.class.blank_value?(value)

          _schema ||= schema
          aliases = required_attribute.aliases.collect do |name|
            self.class.human_attribute_name(name)
          end
          args = [self.class.human_object_class_name(object_class)]
          if aliases.empty?
            format = _("%{fn} is required attribute by objectClass '%s'")
          else
            format = _("%{fn} is required attribute by objectClass " \
                       "'%s': aliases: %s")
            args << aliases.join(', ')
          end
          unless ActiveLdap.get_text_supported?
            format = format.sub(/^%\{fn\} /, '')
          end
          errors.add(real_name, format % args)
        end
      end
    end

    def validate_ldap_values
      entry_attribute.schemata.each do |name, attribute|
        value = self[name]
        next if self.class.blank_value?(value)
        validate_ldap_value(attribute, name, value)
      end
    end

    def validate_ldap_value(attribute, name, value)
      failed_reason, option = attribute.validate(value)
      return if failed_reason.nil?
      if attribute.binary?
        inspected_value = _("<binary-value>")
      else
        inspected_value = self.class.human_readable_format(value)
      end
      params = [inspected_value,
                self.class.human_syntax_description(attribute.syntax),
                failed_reason]
      if option
        format = _("%{fn}(%s) has invalid format: %s: required syntax: %s: %s")
      else
        format = _("%{fn} has invalid format: %s: required syntax: %s: %s")
      end
      params.unshift(option) if option
      unless ActiveLdap.get_text_supported?
        format = format.sub(/^%\{fn\} ?/, '')
      end
      errors.add(name, format % params)
    end
  end
end
