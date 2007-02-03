
module ActiveLdap
  # Configuration
  #
  # Configuration provides the default settings required for
  # ActiveLdap to work with your LDAP server. All of these
  # settings can be passed in at initialization time.
  module Configuration
    def self.included(base)
      base.extend(ClassMethods)
    end

    DEFAULT_CONFIG = {}
    DEFAULT_CONFIG[:host] = '127.0.0.1'
    DEFAULT_CONFIG[:port] = 389
    DEFAULT_CONFIG[:method] = :plain  # :ssl, :tls, :plain allowed

    DEFAULT_CONFIG[:bind_dn] = "cn=admin,dc=localdomain"
    DEFAULT_CONFIG[:password_block] = nil
    DEFAULT_CONFIG[:password] = nil
    DEFAULT_CONFIG[:store_password] = true
    DEFAULT_CONFIG[:allow_anonymous] = true
    DEFAULT_CONFIG[:sasl_quiet] = false
    DEFAULT_CONFIG[:try_sasl] = false
    # See http://www.iana.org/assignments/sasl-mechanisms
    DEFAULT_CONFIG[:sasl_mechanisms] = ["GSSAPI", "CRAM-MD5", "EXTERNAL"]

    DEFAULT_CONFIG[:retry_limit] = 3
    DEFAULT_CONFIG[:retry_wait] = 3
    DEFAULT_CONFIG[:timeout] = 0 # in seconds; 0 <= Never timeout
    # Whether or not to retry on timeouts
    DEFAULT_CONFIG[:retry_on_timeout] = true

    DEFAULT_CONFIG[:logger] = nil

    module ClassMethods
      @@defined_configurations = {}

      def default_configuration
        DEFAULT_CONFIG.dup
      end

      def ensure_configuration(config=nil)
        if config.nil?
          if defined?(LDAP_ENV)
            config = LDAP_ENV
          elsif defined?(RAILS_ENV)
            config = RAILS_ENV
          else
            config = {}
          end
        end

        if config.is_a?(Symbol) or config.is_a?(String)
          _config = configurations[config.to_s]
          unless _config
            raise ConnectionError, "#{config} connection is not configured"
          end
          config = _config
        end

        config
      end

      def configuration(key=nil)
        @@defined_configurations[key || active_connection_name]
      end

      def define_configuration(key, config)
        @@defined_configurations[key] = config
      end

      def defined_configurations
        @@defined_configurations
      end

      def remove_configuration_by_configuration(config)
        @@defined_configurations.delete_if {|key, value| value == config}
      end

      def merge_configuration(config)
        configuration = default_configuration
        config.symbolize_keys.each do |key, value|
          case key
          when :base
            # Scrub before inserting
            self.base = value.gsub(/['}{#]/, '')
          when :ldap_scope
            self.ldap_scope = value
          else
            configuration[key] = value
          end
        end
        configuration
      end
    end
  end
end
