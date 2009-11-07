require 'active_ldap/association/collection'
require 'active_ldap/association/has_many_utils'

module ActiveLdap
  module Association
    class HasManyWrap < Collection
      include HasManyUtils

      private
      def insert_entry(entry)
        old_value = @owner[@options[:wrap], true]
        _foreign_key = foreign_key
        if _foreign_key == "dn"
          old_value = dn_values_to_string_values(old_value)
        end
        current_value = entry[_foreign_key, true]
        current_value = dn_values_to_string_values(current_value)
        new_value = (old_value + current_value).uniq.sort
        if old_value != new_value
          @owner[@options[:wrap]] = new_value
          @owner.save
        end
      end

      def delete_entries(entries)
        old_value = @owner[@options[:wrap], true]
        _foreign_key = foreign_key
        if _foreign_key == "dn"
          old_value = dn_values_to_string_values(old_value)
        end
        current_value = entries.collect {|entry| entry[_foreign_key]}
        current_value = dn_values_to_string_values(current_value)
        new_value = old_value - current_value
        new_value = new_value.uniq.sort
        if old_value != new_value
          @owner[@options[:wrap]] = new_value
          @owner.save
        end
      end

      def find_target
        targets, requested_targets = collect_targets(@options[:wrap], true)
        return [] if targets.nil?

        found_targets = {}
        _foreign_key = foreign_key
        targets.each do |target|
          found_targets[target[_foreign_key]] ||= target
        end

        klass = foreign_class
        requested_targets.collect do |name|
          found_targets[name] || klass.new(name)
        end
      end

      def foreign_key
        @options[:primary_key_name] || foreign_class.dn_attribute
      end
    end
  end
end
