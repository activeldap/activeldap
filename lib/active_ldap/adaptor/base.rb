module ActiveLdap
  module Adaptor
    class Base
      def initialize(config={})
        @connection = nil
        @config = config.dup
        @logger = @config.delete(:logger)
        %w(host port method timeout retry_on_timeout
           retry_limit retry_wait bind_dn password
           password_block try_sasl sasl_mechanisms
           allow_anonymous store_password).each do |name|
          instance_variable_set("@#{name}", config[name.to_sym])
        end
      end

      private
      def need_credential_sasl_mechanism?(mechanism)
        not %(GSSAPI EXTERNAL ANONYMOUS).include?(mechanism)
      end

      def password(bind_dn, options={})
        passwd = options[:password] || @password
        return passwd if passwd

        password_block = options[:password_block] || @password_block
        # TODO: Give a warning to reconnect users with password clearing
        # Get the passphrase for the first time, or anew if we aren't storing
        if password_block.respond_to?(:call)
          passwd = password_block.call(bind_dn)
        else
          @logger.error {'password_block not nil or Proc object. Ignoring.'}
          return nil
        end

        # Store the password for quick reference later
        if options.has_key?(:store_password)
          store_password = options[:store_password]
        else
          store_password = @store_password
        end
        @password = store_password ? passwd : nil

        passwd
      end

      def with_timeout(try_reconnect=true, &block)
        begin
          Timeout.alarm(@timeout, &block)
        rescue Timeout::Error => e
          @logger.error {'Requested action timed out.'}
          retry if try_reconnect and @retry_on_timeout and reconnect
          @logger.error {e.message}
          raise TimeoutError, e.message
        end
      end
    end
  end
end
