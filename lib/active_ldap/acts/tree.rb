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
        def root
          find(:first, :scope => :base)
        end
      end

      # Returns list of ancestors, starting from parent until root.
      #
      #   subchild1.ancestors # => [child1, root]
      def ancestors
        node, nodes = self, []
        nodes << node = node.parent while node.parent
        nodes
      end

      # Returns the root node of the tree.
      def root
        node = self
        node = node.parent while node.parent
        node
      end

      # Returns all siblings of the current node.
      #
      #   subchild1.siblings # => [subchild2]
      def siblings
        self_and_siblings - [self]
      end

      # Returns all siblings and a reference to the current node.
      #
      #   subchild1.self_and_siblings # => [subchild1, subchild2]
      def self_and_siblings
        parent ? parent.children : [self]
      end

      def parent
        if base == self.class.base
          nil
        else
          find(:first, :base => base, :scope => :base)
        end
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
