require 'active_ldap/schema'
require 'active_ldap/ldap_error'

module ActiveLdap
  module Adapter
    class Base
      include GetTextSupport

      VALID_ADAPTER_CONFIGURATION_KEYS = [:host, :port, :method, :timeout,
                                          :retry_on_timeout, :retry_limit,
                                          :retry_wait, :bind_dn, :password,
                                          :password_block, :try_sasl,
                                          :sasl_mechanisms, :sasl_quiet,
                                          :allow_anonymous, :store_password,
                                          :scope]
      def initialize(configuration={})
        @connection = nil
        @disconnected = false
        @configuration = configuration.dup
        @logger = @configuration.delete(:logger)
        @configuration.assert_valid_keys(VALID_ADAPTER_CONFIGURATION_KEYS)
        VALID_ADAPTER_CONFIGURATION_KEYS.each do |name|
          instance_variable_set("@#{name}", configuration[name])
        end
      end

      def connect(options={})
        host = options[:host] || @host
        port = options[:port] || @port
        method = ensure_method(options[:method] || @method)
        @disconnected = false
        @connection = yield(host, port, method)
        prepare_connection(options)
        bind(options)
      end

      def disconnect!(options={})
        return if @connection.nil?
        unbind(options)
        @connection = nil
      end

      def rebind(options={})
        unbind(options) if bound?
        connect(options)
      end

      def bind(options={})
        bind_dn = options[:bind_dn] || @bind_dn
        try_sasl = options.has_key?(:try_sasl) ? options[:try_sasl] : @try_sasl
        if options.has_key?(:allow_anonymous)
          allow_anonymous = options[:allow_anonymous]
        else
          allow_anonymous = @allow_anonymous
        end

        # Rough bind loop:
        # Attempt 1: SASL if available
        # Attempt 2: SIMPLE with credentials if password block
        # Attempt 3: SIMPLE ANONYMOUS if 1 and 2 fail (or pwblock returns '')
        if try_sasl and sasl_bind(bind_dn, options)
          @logger.info {_('Bound by SASL as %s') % bind_dn}
        elsif simple_bind(bind_dn, options)
          @logger.info {_('Bound by simple as %s') % bind_dn}
        elsif allow_anonymous and bind_as_anonymous(options)
          @logger.info {_('Bound as anonymous')}
        else
          message = yield if block_given?
          message ||= _('All authentication methods exhausted.')
          raise AuthenticationError, message
        end

        bound?
      end

      def bind_as_anonymous(options={})
        operation(options) do
          yield
        end
      end

      def connecting?
        !@connection.nil? and !@disconnected
      end

      def schema(options={})
        @schema ||= operation(options) do
          base = options[:base]
          attrs = options[:attributes]

          attrs ||= [
            'objectClasses',
            'attributeTypes',
            'matchingRules',
            'matchingRuleUse',
            'dITStructureRules',
            'dITContentRules',
            'nameForms',
            'ldapSyntaxes',
            #'extendedAttributeInfo', # if we need RANGE-LOWER/UPPER.
          ]
          base ||= root_dse_values('subschemaSubentry', options)[0]
          base ||= 'cn=schema'
          dn, attributes = search(:base => base,
                                  :scope => :base,
                                  :filter => '(objectClass=subschema)',
                                  :attributes => attrs).first
          Schema.new(attributes)
        end
      end

      def search(options={})
        filter = parse_filter(options[:filter]) || 'objectClass=*'
        attrs = options[:attributes] || []
        scope = ensure_scope(options[:scope] || @scope)
        base = options[:base]
        limit = options[:limit] || 0
        limit = nil if limit <= 0

        attrs = attrs.to_a # just in case

        values = []
        callback = Proc.new do |value, block|
          value = block.call(value) if block
          values << value
        end

        begin
          operation(options) do
            yield(base, scope, filter, attrs, limit, callback)
          end
        rescue LdapError
          # Do nothing on failure
          @logger.info do
            args = [$!.class, $!.message, filter, attrs.inspect]
            _("Ignore error %s(%s): filter %s: attributes: %s") % args
          end
        end

        values
      end

      def delete(targets, options={})
        targets = [targets] unless targets.is_a?(Array)
        return if targets.empty?
        target = nil
        begin
          operation(options) do
            targets.each do |target|
              yield(target)
            end
          end
        rescue LdapError::NoSuchObject
          raise EntryNotFound, _("No such entry: %s") % target
        end
      end

      def add(dn, entries, options={})
        begin
          operation(options) do
            yield(dn, entries)
          end
        rescue LdapError::NoSuchObject
          raise EntryNotFound, _("No such entry: %s") % dn
        rescue LdapError::InvalidDnSyntax
          raise DistinguishedNameInvalid.new(dn)
        rescue LdapError::AlreadyExists
          raise EntryAlreadyExist, _("%s: %s") % [$!.message, dn]
        rescue LdapError::StrongAuthRequired
          raise StrongAuthenticationRequired, _("%s: %s") % [$!.message, dn]
        rescue LdapError::ObjectClassViolation
          raise RequiredAttributeMissed, _("%s: %s") % [$!.message, dn]
        rescue LdapError::UnwillingToPerform
          raise OperationNotPermitted, _("%s: %s") % [$!.message, dn]
        end
      end

      def modify(dn, entries, options={})
        begin
          operation(options) do
            yield(dn, entries)
          end
        rescue LdapError::UndefinedType
          raise
        rescue LdapError::ObjectClassViolation
          raise RequiredAttributeMissed, _("%s: %s") % [$!.message, dn]
        end
      end

      def modify_rdn(dn, new_rdn, delete_old_rdn, new_superior, options={})
        operation(options) do
          yield(dn, new_rdn, delete_old_rdn, new_superior)
        end
      end

      private
      def prepare_connection(options)
      end

      def operation(options)
        retried = false
        begin
          reconnect_if_need
          try_reconnect = !options.has_key?(:try_reconnect) ||
                             options[:try_reconnect]
          with_timeout(try_reconnect, options) do
            yield
          end
        rescue Errno::EPIPE
          if retried or !try_reconnect
            raise
          else
            retried = true
            @disconnected = true
            retry
          end
        end
      end

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
          @logger.error {_('password_block not nil or Proc object. Ignoring.')}
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
          @logger.error {_('Requested action timed out.')}
          retry if try_reconnect and @retry_on_timeout and reconnect(options)
          @logger.error {e.message}
          raise TimeoutError, e.message
        end
      end

      def sasl_bind(bind_dn, options={})
        return false unless bind_dn

        # Get all SASL mechanisms
        mechanisms = operation(options) do
          root_dse_values("supportedSASLMechanisms")
        end

        if options.has_key?(:sasl_quiet)
          sasl_quiet = options[:sasl_quiet]
        else
          sasl_quiet = @sasl_quiet
        end

        sasl_mechanisms = options[:sasl_mechanisms] || @sasl_mechanisms
        sasl_mechanisms.each do |mechanism|
          next unless mechanisms.include?(mechanism)
          operation(options) do
            yield(bind_dn, mechanism, sasl_quiet)
            return true if bound?
          end
        end
        false
      end

      def simple_bind(bind_dn, options={})
        return false unless bind_dn

        passwd = password(bind_dn, options)
        return false unless passwd

        begin
          operation(options) do
            yield(bind_dn, passwd)
            bound?
          end
        rescue LdapError::InvalidDnSyntax
          raise DistinguishedNameInvalid.new(bind_dn)
        rescue LdapError::InvalidCredentials
          false
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
              if filter_logical_operator?(key)
                parse_filter(component)
              elsif value.is_a?(Hash)
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

      def extract_filter_value_options(value)
        options = {}
        if value.is_a?(Array)
          case value[0]
          when Hash
            options = value[0]
            value = value[1]
          when "=", "~=", "<=", "=>"
            options[:operator] = value[1]
            value = value[1]
          end
        end
        [value, options]
      end

      def construct_component(key, value, operator=nil)
        value, options = extract_filter_value_options(value)
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
          [
           "(",
           escape_filter_key(key),
           options[:operator] || "=",
           escape_filter_value(value, options),
           ")"
          ].join
        end
      end

      def escape_filter_key(key)
        escape_filter_value(key.to_s)
      end

      def escape_filter_value(value, options={})
        case value
	when Numeric, DN
          value = value.to_s
        when Time
          value = Schema::GeneralizedTime.new.normalize_value(value)
        end
        value.gsub(/(?:[()\\\0]|\*\*?)/) do |s|
          if s == "*"
            s
          else
            s = "*" if s == "**"
            "\\%02X" % s[0]
          end
        end
      end

      def construct_filter(components, operator=nil)
        operator = normalize_filter_logical_operator(operator)
        components = components.compact
        case components.size
        when 0
          nil
        when 1
          filter = components[0]
          filter = "(!#{filter})" if operator == :not
          filter
        else
          "(#{operator == :and ? '&' : '|'}#{components.join})"
        end
      end

      def collection?(object)
        !object.is_a?(String) and object.respond_to?(:each)
      end

      LOGICAL_OPERATORS = [:and, :or, :not, :&, :|]
      def filter_logical_operator?(operator)
        LOGICAL_OPERATORS.include?(operator)
      end

      def normalize_filter_logical_operator(operator)
        assert_filter_logical_operator(operator)
        case (operator || :and)
        when :and, :&
          :and
        when :or, :|
          :or
        else
          :not
        end
      end

      def assert_filter_logical_operator(operator)
        return if operator.nil?
        unless filter_logical_operator?(operator)
          raise ArgumentError,
                _("invalid logical operator: %s: available operators: %s") %
                  [operator.inspect, LOGICAL_OPERATORS.inspect]
        end
      end

      # Attempts to reconnect up to the number of times allowed
      # If forced, try once then fail with ConnectionError if not connected.
      def reconnect(options={})
        options = options.dup
        force = options[:force]
        retry_limit = options[:retry_limit] || @retry_limit
        retry_wait = options[:retry_wait] || @retry_wait
        options[:reconnect_attempts] ||= 0

        loop do
          unless can_reconnect?(options)
            raise ConnectionError,
                  _('Giving up trying to reconnect to LDAP server.')
          end

          @logger.debug {_('Attempting to reconnect')}
          disconnect!

          # Reset the attempts if this was forced.
          options[:reconnect_attempts] = 0 if force
          options[:reconnect_attempts] += 1 if retry_limit >= 0
          begin
            connect(options)
            break
          rescue => detail
            @logger.error do
              _("Reconnect to server failed: %s\n" \
                "Reconnect to server failed backtrace:\n" \
                "%s") % [detail.exception, detail.backtrace.join("\n")]
            end
            # Do not loop if forced
            raise ConnectionError, detail.message if force
          end

          # Sleep before looping
          sleep retry_wait
        end

        true
      end

      def reconnect_if_need(options={})
        reconnect(options) if !connecting? and can_reconnect?(options)
      end

      # Determine if we have exceed the retry limit or not.
      # True is reconnecting is allowed - False if not.
      def can_reconnect?(options={})
        retry_limit = options[:retry_limit] || @retry_limit
        reconnect_attempts = options[:reconnect_attempts] || 0

        retry_limit < 0 or reconnect_attempts < (retry_limit - 1)
      end

      def root_dse_values(key, options={})
        dse = root_dse([key], options)[0]
        return [] if dse.nil?
        dse[key] || dse[key.downcase] || []
      end

      def root_dse(attrs, options={})
        search(:base => "",
               :scope => :base,
               :attributes => attrs).collect do |dn, attributes|
          attributes
        end
      end
    end
  end
end
