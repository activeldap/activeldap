module ActiveLdap
  module Connection
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      @@active_connections = {}
      @@allow_concurrency = false

      def thread_safe_active_connections
        @@active_connections[Thread.current.object_id] ||= {}
      end

      def single_threaded_active_connections
        @@active_connections
      end

      if @@allow_concurrency
        alias_method :active_connections, :thread_safe_active_connections
      else
        alias_method :active_connections, :single_threaded_active_connections
      end

      def allow_concurrency=(threaded) #:nodoc:
        logger.debug {"allow_concurrency=#{threaded}"} if logger
        return if @@allow_concurrency == threaded
        clear_all_cached_connections!
        @@allow_concurrency = threaded
        method_prefix = threaded ? "thread_safe" : "single_threaded"
        sing = (class << self; self; end)
        [:active_connections].each do |method|
          sing.send(:alias_method, method, "#{method_prefix}_#{method}")
        end
      end

      def active_connection_name
        @active_connection_name ||= determine_active_connection_name
      end

      def remove_active_connections!
        active_connections.keys.each do |key|
          remove_connection(key)
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
        ObjectSpace.each_object(Class) do |klass|
          if klass < self and !klass.name.blank? and !klass.frozen?
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

      def connection=(adapter)
        if adapter.is_a?(Adapter::Base)
          active_connections[active_connection_name] = adapter
        elsif adapter.is_a?(Hash)
          config = adapter
          self.connection = instantiate_adapter(config)
        elsif adapter.nil?
          raise ConnectionNotSetup
        else
          setup_connection(adapter)
        end
      end

      def instantiate_adapter(config)
        adapter = (config[:adapter] || default_adapter)
        normalized_adapter = adapter.downcase.gsub(/-/, "_")
        adapter_method = "#{normalized_adapter}_connection"
        unless Adapter::Base.respond_to?(adapter_method)
          raise AdapterNotFound.new(adapter)
        end
        if config.has_key?(:ldap_scope)
          message = _(":ldap_scope connection option is deprecated. " \
                      "Use :scope instead.")
          ActiveSupport::Deprecation.warn(message)
          config[:scope] ||= config.delete(:ldap_scope)
        end
        config = remove_connection_related_configuration(config)
        Adapter::Base.send(adapter_method, config)
      end

      def default_adapter
        @@default_adapter ||= guess_available_adapter
      end

      def connected?
        active_connections[active_connection_name] ? true : false
      end

      def retrieve_connection
        conn = nil
        name = active_connection_name
        raise ConnectionNotSetup unless name
        conn = active_connections[name]
        if conn.nil?
          config = configuration(name)
          raise ConnectionNotSetup unless config
          self.connection = config
          conn = active_connections[name]
        end
        raise ConnectionNotSetup if conn.nil?
        conn
      end

      def remove_connection(klass_or_key=self)
        if klass_or_key.is_a?(Module)
          key = active_connection_key(klass_or_key)
        else
          key = klass_or_key
        end
        config = configuration(key)
        conn = active_connections[key]
        remove_configuration_by_key(key)
        active_connections.delete_if {|_key, value| value == conn}
        conn.disconnect! if conn
        config
      end

      def setup_connection(config=nil)
        config = ensure_configuration(config)
        remove_connection

        clear_active_connection_name
        key = active_connection_key
        @active_connection_name = key
        define_configuration(key, merge_configuration(config))
      end

      def establish_connection(config=nil)
        message =
          _("ActiveLdap::Connection.establish_connection has been deprecated " \
            "since 1.1.0. " \
            "Please use ActiveLdap::Connection.setup_connection instead.")
        ActiveSupport::Deprecation.warn(message)
        setup_connection(config)
      end

      # Return the schema object
      def schema
        connection.schema
      end

      def active_connection_key(k=self)
        k.name.blank? ? k.object_id : k.name
      end

      private
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

      def clear_all_cached_connections!
        if @@allow_concurrency
          @@active_connections.each_value do |connection_hash_for_thread|
            connection_hash_for_thread.each_value {|conn| conn.disconnect!}
            connection_hash_for_thread.clear
          end
        else
          @@active_connections.each_value {|conn| conn.disconnect!}
        end
        @@active_connections.clear
      end

      def guess_available_adapter
        if Object.respond_to?(:java)
          "jndi"
        else
          "net-ldap"
        end
      end
    end

    def setup_connection(config=nil)
      config = self.class.ensure_configuration(config)
      config = self.class.configuration.merge(config)
      config = self.class.merge_configuration(config, self)

      remove_connection
      self.class.define_configuration(dn, config)
    end

    def establish_connection(config=nil)
      message =
        _("ActiveLdap::Connection#establish_connection has been deprecated " \
          "since 1.1.0. " \
          "Please use ActiveLdap::Connection#setup_connection instead.")
      ActiveSupport::Deprecation.warn(message)
      setup_connection(config)
    end

    def remove_connection
      self.class.remove_connection(dn)
      @connection = nil
    end

    def connection
      conn = @connection
      return conn if conn

      have_dn = !@dn.nil?
      if !have_dn and attribute_name_resolvable_without_connection?
        begin
          have_dn = !get_attribute_before_type_cast(dn_attribute)[1].nil?
        rescue DistinguishedNameInvalid
        end
      end
      conn = self.class.active_connections[dn] || retrieve_connection if have_dn
      conn || self.class.connection
    end

    def connected?
      connection != self.class.connection
    end

    def connection=(adapter)
      if adapter.nil? or adapter.is_a?(Adapter::Base)
        @connection = adapter
      elsif adapter.is_a?(Hash)
        config = adapter
        @connection = self.class.instantiate_adapter(config)
      else
        setup_connection(adapter)
      end
    end

    def retrieve_connection
      conn = self.class.active_connections[dn]
      return conn if conn

      config = self.class.configuration(dn)
      return nil unless config

      conn = self.class.instantiate_adapter(config)
      @connection = self.class.active_connections[dn] = conn
      conn
    end

    def schema
      connection.schema
    end
  end
end
