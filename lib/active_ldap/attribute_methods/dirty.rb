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
          @previously_changed = changes
          @changed_attributes.clear
        end
        succeeded
      end

      # Attempts to <tt>save!</tt> the record and clears changed attributes if successful.
      def save!(*) #:nodoc:
        super.tap do
          @previously_changed = changes
          @changed_attributes.clear
        end
      end

      # <tt>reload</tt> the record and clears changed attributes.
      def reload(*) #:nodoc:
        super.tap do
          @previously_changed.clear
          @changed_attributes.clear
        end
      end

    protected
      def set_attribute(name, value)
        if name and name != "objectClass"
          attribute_will_change!(name) unless value == get_attribute(name)
        end
        super
      end
    end
  end
end
