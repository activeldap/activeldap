module ActiveLdap
  module Connection
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      @@active_connections = {}

      def active_connections
        @@active_connections[Thread.current.object_id] ||= {}
      end

      def active_connection_name
        @active_connection_name ||= determine_active_connection_name
      end

      def clear_active_connections!
        connections = active_connections
        connections.each do |key, connection|
          connection.disconnect!
        end
        connections.clear
      end

      def clear_active_connection_name
        @active_connection_name = nil
        ObjectSpace.each_object(Class) do |klass|
          if klass < self and !klass.name.empty?
            klass.instance_variable_set("@active_connection_name", nil)
          end
        end
      end

      def connection
        conn = nil
        @active_connection_name ||= nil
        if @active_connection_name
          conn = active_connections[@active_connection_name]
        end
        unless conn
          conn = retrieve_connection
          active_connections[@active_connection_name] = conn
        end
        conn
      end

      def connection=(adaptor)
        if adaptor.is_a?(Adaptor::Base)
          @schema = nil
          active_connections[active_connection_name] = adaptor
        elsif adaptor.is_a?(Hash)
          config = adaptor
          adaptor = Inflector.camelize(config[:adaptor] || "ldap")
          config = remove_connection_related_configuration(config)
          self.connection = Adaptor.const_get(adaptor).new(config)
        elsif adaptor.nil?
          raise ConnectionNotEstablished
        else
          establish_connection(adaptor)
        end
      end

      def connected?
        active_connections[active_connection_name] ? true : false
      end

      def retrieve_connection
        conn = nil
        name = active_connection_name
        raise ConnectionNotEstablished unless name
        conn = active_connections[name]
        if conn.nil?
          config = configuration(name)
          raise ConnectionNotEstablished unless config
          self.connection = config
          conn = active_connections[name]
        end
        raise ConnectionNotEstablished if conn.nil?
        conn
      end

      def remove_connection(klass=self)
        key = active_connection_key(klass)
        config = configuration(key)
        conn = active_connections[key]
        remove_configuration_by_configuration(config)
        active_connections.delete_if {|key, value| value == conn}
        conn.disconnect! if conn
        config
      end

      def establish_connection(config=nil)
        config = ensure_configuration(config)
        remove_connection

        clear_active_connection_name
        key = active_connection_key
        @active_connection_name = key
        define_configuration(key, merge_configuration(config))
      end

      # Return the schema object
      def schema
        @schema ||= connection.schema
      end

      private
      def active_connection_key(k=self)
        k.name.empty? ? k.object_id : k.name
      end

      def determine_active_connection_name
        key = active_connection_key
        if active_connections[key] or configuration(key)
          key
        elsif self == ActiveLdap::Base
          nil
        else
          superclass.active_connection_name
        end
      end
    end

    def connection
      self.class.connection
    end

    # schema
    #
    # Returns the value of self.class.schema
    # This is just syntactic sugar
    def schema
      self.class.schema
    end
  end
end
