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

      def parse_filter(filter, operator=nil)
        return nil if filter.nil?
        if !filter.is_a?(String) and !filter.respond_to?(:collect)
          filter = filter.to_s
        end

        case filter
        when String
          parse_filter_string(filter)
        when Hash
          components = filter.sort_by {|k, v| k.to_s}.collect do |key, value|
            construct_component(key, value, operator)
          end
          construct_filter(components, operator)
        else
          operator, components = normalize_array_filter(filter, operator)

          components = components.collect do |component|
            if component.is_a?(Array) and component.size == 2
              key, value = component
              if filter_logical_operator?(key) or value.is_a?(Hash)
                parse_filter(value, key)
              else
                construct_component(key, value, operator)
              end
            elsif component.is_a?(Symbol)
              assert_filter_logical_operator(component)
              nil
            else
              parse_filter(component, operator)
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

      def normalize_array_filter(filter, operator=nil)
        filter_operator, *components = filter
        if filter_logical_operator?(filter_operator)
          operator = filter_operator
        else
          components.unshift(filter_operator)
        end
        [operator, components]
      end

      def construct_component(key, value, operator=nil)
        if collection?(value)
          values = []
          value.each do |val|
            if collection?(val)
              values.concat(val.collect {|v| [key, v]})
            else
              values << [key, val]
            end
          end
          values[0] = values[0][1] if filter_logical_operator?(values[0][1])
          parse_filter(values, operator)
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

      def collection?(object)
        !object.is_a?(String) and object.respond_to?(:each)
      end

      LOGICAL_OPERATORS = [:and, :or, :&, :|]
      def filter_logical_operator?(operator)
        LOGICAL_OPERATORS.include?(operator)
      end

      def normalize_filter_logical_operator(operator)
        assert_filter_logical_operator(operator)
        case (operator || :and)
        when :and, :&
          :and
        else
          :or
        end
      end

      def assert_filter_logical_operator(operator)
        return if operator.nil?
        unless filter_logical_operator?(operator)
          raise ArgumentError,
                "invalid logical operator: #{operator.inspect}: " +
                "available operators: #{LOGICAL_OPERATORS.inspect}"
        end
      end
    end
  end
end
