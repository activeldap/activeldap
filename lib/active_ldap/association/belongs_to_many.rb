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
          new_value = old_value - @owner[@options[:foreign_key_name], true]
          new_value = new_value.uniq.sort
          if old_value != new_value
            entry[@options[:many]] = new_value
            entry.save
          end
        end
      end

      def find_target
        key = @options[:many]
        values = @owner[@options[:foreign_key_name], true].compact
        components = values.collect do |value|
          [key, value]
        end
        if components.empty?
          []
        else
          foreign_class.find(:all, :filter => [:or, *components])
        end
      end
    end
  end
end
