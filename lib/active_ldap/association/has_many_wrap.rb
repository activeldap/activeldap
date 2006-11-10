require 'active_ldap/association/collection'

module ActiveLdap
  module Association
    class HasManyWrap < Collection
      private
      def insert_entry(entry)
        new_value = @owner[@options[:wrap], true]
        new_value += entry[primary_key, true]
        @owner[@options[:wrap]] = new_value.uniq
        @owner.save
      end

      def find_target
        foreign_base_key = primary_key
        requested_targets = @owner[@options[:wrap], true]

        filter = requested_targets.collect do |value|
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
        end.join

        klass = foreign_class
        found_targets = {}
        klass.find(:all, :filter => "(|#{filter})").each do |target|
          found_targets[target.send(foreign_base_key)] ||= target
        end

        requested_targets.collect do |name|
          found_targets[name] || klass.new(name)
        end
      end
    end
  end
end
