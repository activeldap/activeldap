
module ActiveLDAP
  # Configuration
  #
  # Configuration provides the default settings required for
  # ActiveLDAP to work with your LDAP server. All of these
  # settings can be passed in at initialization time.
  module Configuration
    def self.included(base)
      base.extend(ClassMethods)
    end

    DEFAULT_CONFIG = {}
    DEFAULT_CONFIG[:host] = '127.0.0.1'
    DEFAULT_CONFIG[:port] = 389
    DEFAULT_CONFIG[:method] = :plain  # :ssl, :tls, :plain allowed

    DEFAULT_CONFIG[:bind_format] = "cn=%s,dc=localdomain"
    DEFAULT_CONFIG[:user] = ENV['USER']
    DEFAULT_CONFIG[:password_block] = nil
    DEFAULT_CONFIG[:password] = nil
    DEFAULT_CONFIG[:store_password] = true
    DEFAULT_CONFIG[:allow_anonymous] = true
    DEFAULT_CONFIG[:sasl_quiet] = false
    DEFAULT_CONFIG[:try_sasl] = false

    DEFAULT_CONFIG[:retry_limit] = 3
    DEFAULT_CONFIG[:retry_wait] = 3
    DEFAULT_CONFIG[:timeout] = 0 # in seconds; 0 <= Never timeout
    # Whether or not to retry on timeouts
    DEFAULT_CONFIG[:retry_on_timeout] = true

    # Whether to return objects by default from find/find_all
    DEFAULT_CONFIG[:return_objects] = false

    DEFAULT_CONFIG[:logger] = nil

    module ClassMethods
      def default_configuration
        DEFAULT_CONFIG.dup
      end
    end
  end
end
