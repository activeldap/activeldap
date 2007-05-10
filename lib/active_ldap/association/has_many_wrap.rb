require 'active_ldap/association/collection'

module ActiveLdap
  module Association
    class HasManyWrap < Collection
      private
      def insert_entry(entry)
        old_value = @owner[@options[:wrap], true]
        new_value = (old_value + entry[primary_key, true]).uniq.sort
        if old_value != new_value
          @owner[@options[:wrap]] = new_value
          @owner.save
        end
      end

      def delete_entries(entries)
        old_value = @owner[@options[:wrap], true]
        new_value = old_value - entries.collect {|entry| entry[primary_key]}
        new_value = new_value.uniq.sort
        if old_value != new_value
          @owner[@options[:wrap]] = new_value
          @owner.save
        end
      end

      def find_target
        foreign_base_key = primary_key
        requested_targets = @owner[@options[:wrap], true]

        components = requested_targets.collect do |value|
          key = val = nil
          if foreign_base_key == "dn"
            key, val = value.split(",")[0].split("=") unless value.empty?
          else
            key, val = foreign_base_key, value
          end
          [key, val]
        end.reject do |key, val|
          key.nil? or val.nil?
        end
        return [] if components.empty?

        klass = foreign_class
        found_targets = {}
        klass.find(:all, :filter => [:or, *components]).each do |target|
          found_targets[target.send(foreign_base_key)] ||= target
        end

        requested_targets.collect do |name|
          found_targets[name] || klass.new(name)
        end
      end
    end
  end
end
