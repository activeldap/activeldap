require "English"
require "cgi"
require 'uri'
begin
  require 'uri/ldaps'
rescue LoadError
  module URI
    class LDAPS < LDAP
      DEFAULT_PORT = 636
    end
    @@schemes['LDAPS'] = LDAPS
  end
end

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
    DEFAULT_CONFIG[:port] = nil
    DEFAULT_CONFIG[:method] = :plain  # :ssl, :tls, :plain allowed
    DEFAULT_CONFIG[:tls_options] = nil

    DEFAULT_CONFIG[:bind_dn] = nil
    DEFAULT_CONFIG[:password_block] = nil
    DEFAULT_CONFIG[:password] = nil
    DEFAULT_CONFIG[:store_password] = true
    DEFAULT_CONFIG[:allow_anonymous] = true
    DEFAULT_CONFIG[:sasl_quiet] = true
    DEFAULT_CONFIG[:try_sasl] = false
    DEFAULT_CONFIG[:sasl_options] = nil
    # See http://www.iana.org/assignments/sasl-mechanisms
    DEFAULT_CONFIG[:sasl_mechanisms] = ["GSSAPI", "DIGEST-MD5",
                                        "CRAM-MD5", "EXTERNAL"]

    DEFAULT_CONFIG[:retry_limit] = 1
    DEFAULT_CONFIG[:retry_wait] = 1
    DEFAULT_CONFIG[:timeout] = 0 # in seconds; 0 <= Never timeout
    # Whether or not to retry on timeouts
    DEFAULT_CONFIG[:retry_on_timeout] = true
    DEFAULT_CONFIG[:follow_referrals] = true

    # 500 is the default size limit value of OpenLDAP 2.4:
    #   https://openldap.org/doc/admin24/limits.html#Global%20Limits
    #
    # We may change this when we find LDAP server that its the default
    # size limit is smaller than 500.
    DEFAULT_CONFIG[:page_size] = 500
    # Whether using paged results if available.
    DEFAULT_CONFIG[:use_paged_results] = true

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
          elsif defined?(Rails)
            config = Rails.env
          else
            config = {}
          end
        end

        if config.is_a?(Symbol) or config.is_a?(String)
          _config = configurations[config.to_s]
          unless _config
            raise ConnectionError,
                  _("%s connection is not configured") % config
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

      def remove_configuration_by_key(key)
        @@defined_configurations.delete(key)
      end

      CONNECTION_CONFIGURATION_KEYS = [:uri, :base, :adapter]
      def remove_connection_related_configuration(config)
        config.reject do |key, value|
          CONNECTION_CONFIGURATION_KEYS.include?(key)
        end
      end

      def parent_configuration(target)
        if target.is_a?(Base)
          target = target.class
        else
          target = target.superclass
        end
        while target <= Base
          config = defined_configurations[target.active_connection_key]
          return config if config
          target = target.superclass
        end
        default_configuration
      end

      def merge_configuration(user_configuration, target=self)
        configuration = parent_configuration(target).dup
        prepare_configuration(user_configuration).each do |key, value|
          case key
          when :base
            # Scrub before inserting
            target.base = value.gsub(/['}{#]/, '')
          when :scope, :ldap_scope
            if key == :ldap_scope
              message = _(":ldap_scope configuration option is deprecated. " \
                          "Use :scope instead.")
              ActiveSupport::Deprecation.warn(message)
            end
            target.scope = value
            configuration[:scope] = value
          else
            configuration[key] = value
          end
        end
        configuration
      end

      def prepare_configuration(configuration)
        configuration = configuration.symbolize_keys
        uri = configuration.delete(:uri)
        return configuration unless uri

        begin
          uri = URI.parse(uri)
        rescue URI::InvalidURIError
          raise ConfigurationError.new(_("invalid URI: %s") % uri)
        end
        unless uri.is_a?(URI::LDAP)
          raise ConfigurationError.new(_("not a LDAP URI: %s") % uri.to_s)
        end

        merger = URIConfigurationMerger.new(uri)
        merger.merge(configuration)
      end

      class URIConfigurationMerger
        def initialize(uri)
          @uri = uri
        end

        def merge(configuration)
          uri_configuration = {:port => @uri.port}
          uri_configuration[:host] = @uri.host if @uri.host
          uri_configuration[:base] = @uri.dn if @uri.dn
          extensions = parse_extensions
          bindname_extension = extensions["bindname"]
          if bindname_extension
            uri_configuration[:bind_dn] = bindname_extension[:value]
            uri_configuration[:allow_anonymous] = !bindname_extension[:critical]
          end
          uri_configuration[:scope] = @uri.scope if @uri.scope
          uri_configuration[:method] = :ssl if @uri.is_a?(URI::LDAPS)
          uri_configuration.merge(configuration)
        end

        private
        def parse_extensions
          extensions = {}
          (@uri.extensions || "").split(",").collect do |extension|
            name, value = extension.split("=", 2)
            case name
            when /\A!/
              critical = true
              name = $POSTMATCH
            else
              critical = false
            end
            extensions[name] = {
              :critical => critical,
              :value => CGI.unescape(value || ""),
            }
          end
          extensions
        end
      end
    end
  end
end
