require 'active_ldap/association/collection'

module ActiveLdap
  module Association
    class HasMany < Collection
      private
      def insert_entry(entry)
        entry[primary_key] = @owner[@options[:foreign_key_name]]
        entry.save
      end

      def find_target
        foreign_base_key = primary_key
        components = @owner[@options[:foreign_key_name], true].collect do |value|
          key = val = nil
          if foreign_base_key == "dn"
            key, val = value.split(",")[0].split("=") unless value.empty?
          else
            key, val = foreign_base_key, value
          end
          [key, val]
        end.reject do |key, val|
          key.nil? or val.nil?
        end.collect do |key, val|
          "(#{key}=#{val})"
        end
        foreign_class.find(:all, :filter => [:or, *components])
      end

      def delete_entries(entries)
        key = primary_key
        dn_attribute = foreign_class.dn_attribute
        components = @owner[@options[:foreign_key_name], true].reject do |value|
          value.nil?
        end.collect do |value|
          "(#{key}=#{value})"
        end
        filter = [:and, *components]
        entry_components = entries.collect do |entry|
          "(#{dn_attribute}=#{entry.id})"
        end
        entry_filter = [:or, *entry_components]
        foreign_class.update_all({primary_key => []},
                                 [:and, filter, entry_filter])
      end
    end
  end
end
