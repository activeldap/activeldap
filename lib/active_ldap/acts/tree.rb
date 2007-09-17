module ActiveLdap
  module Acts
    module Tree
      def self.included(base)
        base.class_eval do
          extend(ClassMethods)
          association_accessor(:children) do |target|
            Association::Children.new(target, {})
          end
        end
      end

      module ClassMethods
        def roots
          find(:all, :scope => :one)
        end

        def root
          find(:first, :scope => :one)
        end
      end

      include ActiveRecord::Acts::Tree::InstanceMethods

      def parent
        find(:first, :base => base, :scope => :base)
      end

      def parent=(entry)
        if entry.is_a?(String)
          base = entry
        elsif entry.respond_to?(:dn)
          base = entry.dn
          if entry.respond_to?(:clear_association_cache)
            entry.clear_association_cache
          end
        else
          message = _("parent must be an entry or parent DN: %s") % entry.inspect
          raise ArgumentError, message
        end
	destroy unless new_entry?
        self.dn = "#{dn_attribute}=#{id},#{base}"
        save
      end
    end
  end
end
