require 'activeldap/association/collection'

module ActiveLDAP
  module Association
    class HasMany < Collection
      private
      def insert_entry(entry)
        entry[primary_key] = @owner[@options[:foreign_key_name]]
        entry.save
      end

      def load_target
        foreign_base_key = primary_key
        filter = @owner[@options[:foreign_key_name], false].collect do |value|
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
        @target = foreign_class.find(:all, :filter => "(|#{filter})")
      end
    end
  end
end
