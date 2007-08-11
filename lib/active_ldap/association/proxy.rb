module ActiveLdap
  module Association
    class Proxy
      alias_method :proxy_respond_to?, :respond_to?
      alias_method :proxy_extend, :extend

      def initialize(owner, options)
        @owner = owner
        @options = options
        extend(options[:extend]) if options[:extend]
        reset
      end

      def respond_to?(symbol, include_priv=false)
        proxy_respond_to?(symbol, include_priv) or
          (load_target && @target.respond_to?(symbol, include_priv))
      end

      def ===(other)
        load_target and other === @target
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

      def exists?
        load_target
        not @target.nil?
      end

      private
      def method_missing(method, *args, &block)
        load_target
        @target.send(method, *args, &block)
      end

      def foreign_class
        klass = @owner.class.associated_class(@options[:association_id])
        klass = @owner.class.module_eval(klass) if klass.is_a?(String)
        klass
      end

      def have_foreign_key?
        false
      end

      def primary_key
        @options[:primary_key_name] || foreign_class.dn_attribute
      end

      def load_target
        if !@owner.new_entry? or have_foreign_key?
          begin
            @target = find_target unless loaded?
          rescue EntryNotFound
            reset
          end
        end

        loaded if target
        target
      end

      def find_options(options={})
        if @owner.connection != @owner.class.connection
          {:connection => @owner.connection}.merge(options)
        else
          options
        end
      end

      def infect_connection(target)
        conn = @owner.instance_variable_get("@connection")
        target.connection = conn if conn
      end
    end
  end
end
