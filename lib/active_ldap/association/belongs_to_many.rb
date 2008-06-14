require 'active_ldap/association/collection'

module ActiveLdap
  module Association
    class BelongsToMany < Collection
      private
      def insert_entry(entry)
        old_value = entry[@options[:many], true]
        new_value = old_value + @owner[@options[:foreign_key_name], true]
        new_value = new_value.uniq.sort
        if old_value != new_value
          entry[@options[:many]] = new_value
          entry.save
        end
      end

      def delete_entries(entries)
        entries.each do |entry|
          old_value = entry[@options[:many], true]
          foreign_key_name = @options[:foreign_key_name]
          if foreign_key_name == "dn"
            old_value = dn_values_to_string_values(old_value)
          end
          new_value = old_value - @owner[foreign_key_name, true]
          new_value = new_value.uniq.sort
          if old_value != new_value
            entry[@options[:many]] = new_value
            entry.save
          end
        end
      end

      def find_target
        values = @owner[@options[:foreign_key_name], true].compact
        return [] if values.empty?

        key = @options[:many]
        components = values.collect do |value|
          [key, value]
        end
        options = find_options(:filter => [:or, *components])
        foreign_class.find(:all, options)
      end

      def dn_values_to_string_values(values)
        values.collect do |value|
          if value.is_a?(DN)
            value.to_s
          else
            value
          end
        end
      end
    end
  end
end
