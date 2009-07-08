require 'active_ldap/association/collection'
require 'active_ldap/association/has_many_utils'

module ActiveLdap
  module Association
    class HasMany < Collection
      include HasManyUtils

      private
      def insert_entry(entry)
        entry[@options[:foreign_key_name]] = @owner[primary_key]
        entry.save
      end

      def find_target
        collect_targets(:primary_key_name)
      end

      def delete_entries(entries)
        key = @options[:foreign_key_name]
        components = @owner[primary_key, true].reject do |value|
          value.nil?
        end
        filter = [:and,
                  [:and, {key => components}],
                  [:or, {foreign_class.dn_attribute => entries.collect(&:id)}]]
        foreign_class.update_all({key => []}, filter)
      end
    end
  end
end
