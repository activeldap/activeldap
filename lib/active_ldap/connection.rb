module ActiveLdap
  module Connection
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      @@defined_configurations = {}
      @@active_connections = {}

      def active_connections
        @@active_connections[Thread.current.object_id] ||= {}
      end

      def active_connection_name
        return @active_connection_name if @active_connection_name
        key = active_connection_key
        if active_connections[key] or @@defined_configurations[key]
          @active_connection_name = key
        elsif self == ActiveLdap::Base
          @active_connection_name = nil
        else
          @active_connection_name = superclass.active_connection_name
        end
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
        ObjectSpace.each_object(Class) do |k|
          k.clear_active_connection_name if k < self
        end
      end

      def connection
        conn = nil
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
          active_connections[active_connection_key] = adaptor
        elsif adaptor.is_a?(Hash)
          config = adaptor
          adaptor = to_class_name(config[:adaptor] || "ldap")
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
          config = @@defined_configurations[name]
          raise ConnectionNotEstablished unless config
          self.connection = config
          conn = active_connections[name]
        end
        raise ConnectionNotEstablished if conn.nil?
        conn
      end

      def remove_connection(klass=self)
        key = active_connection_key(klass)
        config = @@defined_configurations[key]
        conn = active_connections[key]
        @@defined_configurations.delete_if {|key, value| value == config}
        active_connections.delete_if {|key, value| value == conn}
        conn.disconnect! if conn
        config
      end

      def establish_connection(config=nil)
        remove_connection
        init_configuration(config || {})
        clear_active_connection_name
        key = active_connection_key
        @action_connection_name = key
        @@defined_configurations[key] = configuration
      end

      # Return the schema object
      def schema
        @schema ||= connection.schema
      end

      private
      def active_connection_key(k=self)
        k.name.empty? ? k.object_id : k.name
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
      logger.debug {"stub: called schema"}
      self.class.schema
    end
  end
end
