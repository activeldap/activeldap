require 'active_record/validations'

module ActiveLdap
  module Validations
    def self.append_features(base)
      super

      base.class_eval do
        alias_method :new_record?, :new_entry?
        include ActiveRecord::Validations

        validate :validate_required_values

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

        # validate_required_values
        #
        # Basic validation:
        # - Verify that every 'MUST' specified in the schema has a value defined
        def validate_required_values
          logger.debug {"stub: validate_required_values called"}

          # Make sure all MUST attributes have a value
          @musts.each do |object_class, attributes|
            attributes.each do |required_attribute|
              # Normalize to ensure we catch schema problems
              real_name = to_real_attribute_name(required_attribute, true)
              raise UnknownAttribute.new(required_attribute) if real_name.nil?
              # # Set default if it wasn't yet set.
              # @data[real_name] ||= [] # need?
              value = @data[real_name] || []
              # Check for missing requirements.
              if value.empty?
                aliases = schema.attribute_aliases(real_name) - [real_name]
                message = "is required attribute "
                unless aliases.empty?
                  message << "(aliases: #{aliases.join(', ')}) "
                end
                message << "by objectClass '#{object_class}'"
                errors.add(real_name, message)
              end
            end
          end
          logger.debug {"stub: validate_required_values finished"}
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
  end
end
