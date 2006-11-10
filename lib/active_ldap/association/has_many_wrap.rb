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
        filter = @owner[@options[:wrap], true].collect do |value|
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
        foreign_class.find(:all, :filter => "(|#{filter})")
      end
    end
  end
end
