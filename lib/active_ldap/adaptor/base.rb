module ActiveLdap
  module Adaptor
    class Base
      def initialize(config={})
        @connection = nil
        @config = config.dup
        @logger = @config.delete(:logger)
        %w(host port method timeout retry_on_timeout
           retry_limit retry_wait bind_dn password
           password_block try_sasl allow_anonymous
           store_password).each do |name|
          instance_variable_set("@#{name}", config[name.to_sym])
        end
      end

      private
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
