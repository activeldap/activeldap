require 'activeldap/association/proxy'

module ActiveLDAP
  module Association
    class BelongsTo < Proxy
      def replace(entry)
        if entry.nil?
          @target = @owner[@options[:foreign_key_name]] = nil
        else
          @target = (Proxy === entry ? entry.target : entry)
          unless entry.new_entry?
            @owner[@options[:foreign_key_name]] = entry[primary_key]
          end
          @updated = true
        end

        loaded
        entry
      end

      def updated?
        @updated
      end

      private
      def have_foreign_key?
        not @owner[@options[:foreign_key_name]].nil?
      end

      def find_target
        filter = "(#{primary_key}=#{@owner[@options[:foreign_key_name]]})"
        result = foreign_class.find(:all, :filter => filter)
        raise EntryNotFound if result.empty?
        result.first
      end
    end
  end
end
