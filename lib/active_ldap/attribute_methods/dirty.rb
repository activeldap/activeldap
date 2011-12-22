#
module ActiveLdap
  module AttributeMethods
    module Dirty
      extend ActiveSupport::Concern
      include ActiveModel::Dirty

      # Attempts to +save+ the record and clears changed attributes if successful.
      def save(*) #:nodoc:
        if status = super
          changed_attributes.clear
        end
        status
      end

      # Attempts to <tt>save!</tt> the record and clears changed attributes if successful.
      def save!(*) #:nodoc:
        if status = super
          changed_attributes.clear
        end
        status
      end

      # <tt>reload</tt> the record and clears changed attributes.
      def reload(*) #:nodoc:
        super.tap do
          changed_attributes.clear
        end
      end

      module ClassMethods
        # dirty/clear hack
        # only place that we can ovveride and hook to clear the new record
        def find_every(options)
          super.each do |result|
            result.changed_attributes.clear
          end
        end
      end

    protected
      def attribute=(attr, val)
        attribute_will_change!(attr) unless val == get_attribute(attr)
        super
      end
    end
  end
end
