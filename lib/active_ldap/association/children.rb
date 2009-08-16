require 'active_ldap/association/collection'

module ActiveLdap
  module Association
    class Children < Collection
      private
      def insert_entry(entry)
        entry.dn = [entry.id, @owner.dn.to_s].join(",")
        entry.save
      end

      def find_target
        @owner.find(:all, :base => @owner.dn, :scope => :one)
      end

      def delete_entries(entries)
        entries.each(&:destroy)
      end
    end
  end
end
