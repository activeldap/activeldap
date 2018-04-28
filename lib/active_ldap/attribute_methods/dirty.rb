#
module ActiveLdap
  module AttributeMethods
    module Dirty
      extend ActiveSupport::Concern
      include ActiveModel::Dirty

      # Attempts to +save+ the record and clears changed attributes if successful.
      def save(*) #:nodoc:
        succeeded = super
        if succeeded
          changes_applied
        end
        succeeded
      end

      # Attempts to <tt>save!</tt> the record and clears changed attributes if successful.
      def save!(*) #:nodoc:
        super.tap do
          changes_applied
        end
      end

      # <tt>reload</tt> the record and clears changed attributes.
      def reload(*) #:nodoc:
        super.tap do
          clear_changes_information
        end
      end

      private
      def set_attribute(name, value)
        if name and name != "objectClass"
          attribute_will_change!(name) unless value == get_attribute(name)
        end
        super
      end
    end
  end
end
