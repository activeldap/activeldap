require 'active_ldap/association/collection'
require 'active_ldap/association/has_many_utils'

module ActiveLdap
  module Association
    class HasManyWrap < Collection
      include HasManyUtils

      private
      def insert_entry(entry)
        old_value = @owner[@options[:wrap], true]
        _primary_key = primary_key
        if _primary_key == "dn"
          old_value = dn_values_to_string_values(old_value)
        end
        new_value = (old_value + entry[_primary_key, true]).uniq.sort
        if old_value != new_value
          @owner[@options[:wrap]] = new_value
          @owner.save
        end
      end

      def delete_entries(entries)
        old_value = @owner[@options[:wrap], true]
        _primary_key = primary_key
        if _primary_key == "dn"
          old_value = dn_values_to_string_values(old_value)
        end
        new_value = old_value - entries.collect {|entry| entry[_primary_key]}
        new_value = new_value.uniq.sort
        if old_value != new_value
          @owner[@options[:wrap]] = new_value
          @owner.save
        end
      end

      def find_target
        targets, requested_targets = collect_targets(:wrap, true)
        return [] if targets.nil?

        found_targets = {}
        foreign_base_key = primary_key
        targets.each do |target|
          found_targets[target[foreign_base_key]] ||= target
        end

        klass = foreign_class
        requested_targets.collect do |name|
          found_targets[name] || klass.new(name)
        end
      end
    end
  end
end
