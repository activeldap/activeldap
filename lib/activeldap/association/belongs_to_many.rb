require 'activeldap/association/collection'

module ActiveLDAP
  module Association
    class BelongsToMany < Collection
      private
      def insert_entry(entry)
        new_value = entry[@options[:many], false]
        new_value += @owner[@options[:foreign_key_name], false]
        entry[@options[:many]] = new_value.uniq
        entry.save
      end

      def find_target
        key = @options[:many]
        filter = @owner[@options[:foreign_key_name], false].reject do |value|
          value.nil?
        end.collect do |value|
          "(#{key}=#{value})"
        end.join
        foreign_class.find(:all, :filter => "(|#{filter})")
      end
    end
  end
end
