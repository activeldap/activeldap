require 'active_ldap/association/collection'

module ActiveLdap
  module Association
    class BelongsToMany < Collection
      private
      def insert_entry(entry)
        _foreign_class = foreign_class
        entry = _foreign_class.find(entry) unless entry.is_a?(_foreign_class)
        old_value = entry[@options[:many], true]
        primary_key_name = @options[:primary_key_name]
        if primary_key_name == "dn"
          old_value = dn_values_to_string_values(old_value)
        end
        current_value = @owner[primary_key_name, true]
        current_value = dn_values_to_string_values(current_value)
        new_value = old_value + current_value
        new_value = new_value.uniq.sort
        if old_value != new_value
          entry[@options[:many]] = new_value
          entry.save
        end
      end

      def delete_entries(entries)
          _foreign_class = foreign_class
        entries.each do |entry|
          entry = _foreign_class.find(entry) unless entry.is_a?(_foreign_class)
          old_value = entry[@options[:many], true]
          primary_key_name = @options[:primary_key_name]
          if primary_key_name == "dn"
            old_value = dn_values_to_string_values(old_value)
          end
          current_value = @owner[primary_key_name, true]
          current_value = dn_values_to_string_values(current_value)
          new_value = old_value - current_value
          new_value = new_value.uniq.sort
          if old_value != new_value
            entry[@options[:many]] = new_value
            entry.save
          end
        end
      end

      def find_target
        values = @owner[@options[:primary_key_name], true].compact
        return [] if values.empty?

        key = @options[:many]
        components = values.collect do |value|
          [key, value]
        end
        options = find_options(:filter => [:or, *components])
        foreign_class.find(:all, options)
      end
    end
  end
end
