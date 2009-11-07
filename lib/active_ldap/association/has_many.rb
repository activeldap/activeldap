require 'active_ldap/association/collection'
require 'active_ldap/association/has_many_utils'

module ActiveLdap
  module Association
    class HasMany < Collection
      include HasManyUtils

      private
      def insert_entry(entry)
        entry[foreign_key] = @owner[primary_key]
        entry.save
      end

      def find_target
        collect_targets(primary_key)
      end

      def delete_entries(entries)
        _foreign_key = foreign_key
        components = @owner[primary_key, true].reject do |value|
          value.nil?
        end
        filter = [:and,
                  [:and, {_foreign_key => components}],
                  [:or, {foreign_class.dn_attribute => entries.collect(&:id)}]]
        foreign_class.update_all({_foreign_key => []}, filter)
      end
    end
  end
end
