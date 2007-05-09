require 'active_ldap/schema'
require 'active_ldap/ldap_error'

module ActiveLdap
  module Adapter
    class Base
      VALID_ADAPTER_CONFIGURATION_KEYS = [:host, :port, :method, :timeout,
                                          :retry_on_timeout, :retry_limit,
                                          :retry_wait, :bind_dn, :password,
                                          :password_block, :try_sasl,
                                          :sasl_mechanisms, :sasl_quiet,
                                          :allow_anonymous, :store_password]
      def initialize(configuration={})
        @connection = nil
        @configuration = configuration.dup
        @logger = @configuration.delete(:logger)
        @configuration.assert_valid_keys(VALID_ADAPTER_CONFIGURATION_KEYS)
        VALID_ADAPTER_CONFIGURATION_KEYS.each do |name|
          instance_variable_set("@#{name}", configuration[name])
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

      def with_timeout(try_reconnect=true, options={}, &block)
        begin
          Timeout.alarm(@timeout, &block)
        rescue Timeout::Error => e
          @logger.error {'Requested action timed out.'}
          retry if try_reconnect and @retry_on_timeout and reconnect(options)
          @logger.error {e.message}
          raise TimeoutError, e.message
        end
      end

      def parse_filter(filter)
        return nil if filter.nil?
        if !filter.is_a?(String) and !filter.respond_to?(:collect)
          filter = filter.to_s
        end

        case filter
        when String
          parse_filter_string(filter)
        when Hash
          components = filter.sort_by {|k, v| k.to_s}.collect do |key, value|
            construct_component(key, value)
          end
          construct_filter(components)
        else
          operator, *components = filter
          unless operator.is_a?(Symbol)
            components.unshift(operator)
            operator = nil
          end

          components = components.collect do |key, value, *others|
            if value.nil?
              parse_filter(key)
            elsif !others.empty?
              parse_filter([key, value, *others])
            else
              construct_component(key, value)
            end
          end
          construct_filter(components, operator)
        end
      end

      def parse_filter_string(filter)
        if /\A\s*\z/.match(filter)
          nil
        else
          if filter[0, 1] == "("
            filter
          else
            "(#{filter})"
          end
        end
      end

      def construct_component(key, value)
        if !value.is_a?(String) and value.respond_to?(:collect)
          values = value.collect {|v| [key, v]}
          if values[0][1].is_a?(Symbol)
            _, operator = values.shift
            values.unshift(operator)
          end
          parse_filter(values)
        else
          "(#{key}=#{value})"
        end
      end

      def construct_filter(components, operator=nil)
        operator = normalize_filter_logical_operator(operator)
        components = components.compact
        case components.size
        when 0
          nil
        when 1
          components.join
        else
          "(#{operator == :and ? '&' : '|'}#{components.join})"
        end
      end

      def normalize_filter_logical_operator(type)
        case (type || :and)
        when :and, :&
          :and
        when :or, :|
          :or
        else
          operators = [:and, :or, :&, :|]
          raise ArgumentError,
                "invalid logical operator: #{type.inspect}: " +
                "available operators: #{operators.inspect}"
        end
      end
    end
  end
end
