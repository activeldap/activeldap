require 'active_ldap/association/proxy'

module ActiveLdap
  module Association
    class BelongsTo < Proxy
      def replace(entry)
        if entry.nil?
          @target = @owner[@options[:foreign_key_name]] = nil
        else
          @target = (Proxy === entry ? entry.target : entry)
          infect_connection(@target)
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
        value = @owner[@options[:foreign_key_name]]
        raise EntryNotFound if value.nil?
        key = primary_key
        if key == "dn"
          result = foreign_class.find(value, find_options)
        else
          filter = {key => value}
          options = find_options(:filter => filter, :limit => 1)
          result = foreign_class.find(:all, options).first
        end
        raise EntryNotFound if result.nil?
        result
      end
    end
  end
end
