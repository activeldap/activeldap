module ActiveLDAP
  module Association
    class Proxy
      def initialize(owner, options)
        @owner = owner
        @options = options
      end

      def reset
        @target = nil
        @loaded = false
      end

      def reload
        reset
        load_target
      end

      def loaded?
        @loaded
      end

      def loaded
        @loaded = true
      end

      def target
        @target
      end

      def target=(target)
        @target = target
        loaded
      end

      private
      def foreign_class
        klass = @owner.class.has_many_association(@options[:association_id])
        klass = @owner.class.module_eval("#{klass}") if klass.is_a?(String)
        klass
      end

      def primary_key
        @options[:primary_key_name] || foreign_class.dn_attribute
      end
    end
  end
end
