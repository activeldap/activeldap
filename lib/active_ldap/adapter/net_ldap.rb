require 'active_ldap/adapter/base'

module ActiveLdap
  module Adapter
    class Base
      class << self
        def net_ldap_connection(options)
          unless defined?(::Net::LDAP)
            require 'active_ldap/adapter/net_ldap_ext'
          end
          NetLdap.new(options)
        end
      end
    end

    class NetLdap < Base
      METHOD = {
        :ssl => :simple_tls,
        :tls => :start_tls,
        :plain => nil,
      }

      def connect(options={})
        @bound = false

        method = ensure_method(options[:method] || @method)
        host = options[:host] || @host
        port = options[:port] || @port

        config = {
          :host => host,
          :port => port,
          :encryption => {:method => method},
        }
        @connection = Net::LDAP::Connection.new(config)
        bind(options)
      end

      def schema(options={})
        @schema ||= operation(options) do
          base = options[:base]
          attrs = options[:attributes]

          key = 'subschemaSubentry'
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
          base ||= root_dse([key])[key][0]
          base ||= 'cn=schema'
          result = search(:base => base,
                          :scope => :base,
                          :filter => '(objectClass=subschema)',
                          :attributes => attrs)[0][1]
          Schema.new(result)
        end
#       rescue
#         raise ConnectionError.new("Unable to retrieve schema from " +
#                                   "server (#{@method.class.downcase})")
      end

      def disconnect!(options={})
        return if @connection.nil?
        unbind(options)
        @connection = nil
      end

      def unbind(options={})
        @bound = false
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

        begin
          # Rough bind loop:
          # Attempt 1: SASL if available
          # Attempt 2: SIMPLE with credentials if password block
          # Attempt 3: SIMPLE ANONYMOUS if 1 and 2 fail (or pwblock returns '')
          if try_sasl and sasl_bind(bind_dn, options)
            @bound = true
            @logger.info {'Bound SASL'}
          elsif simple_bind(bind_dn, options)
            @bound = true
            @logger.info {'Bound simple'}
          elsif allow_anonymous and bind_as_anonymous(options)
            @bound = true
            @logger.info {'Bound anonymous'}
          else
            @bound = false
            raise AuthenticationError, 'All authentication methods exhausted.'
          end
        rescue Net::LDAP::LdapError
          raise AuthenticationError, $!.message
        end

        bound?
      end

      def bind_as_anonymous(options={})
        @logger.info {"Attempting anonymous authentication"}
        operation(options) do
          (@connection.bind :method => :anonymous).zero?
        end
      end

      def connecting?
        not @connection.nil?
      end

      def bound?
        connecting? and @bound
      end

      def search(options={})
        filter = parse_filter(options[:filter] || 'objectClass=*')
        attrs = options[:attributes] || []
        scope = ensure_scope(options[:scope])
        base = options[:base]
        limit = options[:limit] || 0
        limit = nil if limit <= 0

        results = []
        attrs = attrs.to_a # just in case

        begin
          operation(options) do
            args = {
              :base => base,
              :scope => scope,
              :filter => filter,
              :attributes => attrs,
              :size => limit,
            }
            execute(:search, args) do |entry|
              attributes = {}
              entry.original_attribute_names.each do |name|
                attributes[name] = entry[name]
              end
              value = [entry.dn, attributes]
              value = yield(value) if block_given?
              results.push(value)
            end
          end
        rescue LdapError
          # Do nothing on failure
          @logger.debug {"Ignore error #{$!.class}(#{$!.message}) " +
                         "for #{filter} and attrs #{attrs.inspect}"}
        end

        results
      end

      def to_ldif(dn, attributes)
        entry = Net::LDAP::Entry.new(dn.dup)
        attributes.each do |key, values|
          entry[key] = values.flatten
        end
        entry.to_ldif
      end

      def load(ldifs, options={})
        operation(options) do
          ldifs.split(/(?:\r?\n){2,}/).each do |ldif|
            entry = Net::LDAP::Entry.from_single_ldif_string(ldif)
            attributes = {}
            entry.each do |name, values|
              attributes[name] = values
            end
            attributes.delete(:dn)
            execute(:add,
                    :dn => entry.dn,
                    :attributes => attributes)
          end
        end
      end

      def delete(targets, options={})
        targets = [targets] unless targets.is_a?(Array)
        return if targets.empty?
        target = nil
        begin
          operation(options) do
            targets.each do |target|
              execute(:delete, :dn => target)
            end
          end
        rescue LdapError::NoSuchObject
          raise EntryNotFound, "No such entry: #{target}"
        end
      end

      def add(dn, entries, options={})
        begin
          operation(options) do
            attributes = {}
            entries.each do |type, key, attrs|
              attrs.each do |name, values|
                attributes[name] = values
              end
            end
            execute(:add,
                    :dn => dn,
                    :attributes => attributes)
          end
        rescue LdapError::NoSuchObject
          raise EntryNotFound, "No such entry: #{dn}"
        rescue LdapError::InvalidDnSyntax
          raise DistinguishedNameInvalid.new(dn)
        rescue LdapError::AlreadyExists
          raise EntryAlreadyExist, "#{$!.message}: #{dn}"
        rescue LdapError::StrongAuthRequired
          raise StrongAuthenticationRequired, "#{$!.message}: #{dn}"
        rescue LdapError::ObjectClassViolation
          raise RequiredAttributeMissed, "#{$!.message}: #{dn}"
        rescue LdapError::UnwillingToPerform
          raise OperationNotPermitted, "#{$!.message}: #{dn}"
        end
      end

      def modify(dn, entries, options={})
        begin
          operation(options) do
            execute(:modify,
                    :dn => dn,
                    :operations => parse_entries(entries))
          end
        rescue LdapError::UndefinedType
          raise
        rescue LdapError::ObjectClassViolation
          raise RequiredAttributeMissed, "#{$!.message}: #{dn}"
        end
      end

      private
      def operation(options={}, &block)
        reconnect_if_need
        try_reconnect = !options.has_key?(:try_reconnect) ||
                           options[:try_reconnect]
        with_timeout(try_reconnect, options) do
          block.call
        end
      end

      def execute(method, *args, &block)
        result = @connection.send(method, *args, &block)
        message = nil
        if result.is_a?(Hash)
          message = result[:errorMessage]
          result = result[:resultCode]
        end
        unless result.zero?
          klass = LdapError::ERRORS[result]
          klass ||= LdapError
          raise klass,
                [Net::LDAP.result2string(result), message].compact.join(": ")
        end
      end

      def root_dse(attrs)
        entry = search(:base => "",
                       :scope => :base,
                       :attributes => attrs).first
        dn, attributes = entry
        attributes
      end

      def ensure_method(method)
        method ||= "plain"
        normalized_method = method.to_s.downcase.to_sym
        return METHOD[normalized_method] if METHOD.has_key?(normalized_method)

        available_methods = METHOD.keys.collect {|m| m.inspect}.join(", ")
        raise ConfigurationError,
                "#{method.inspect} is not one of the available connect " +
                "methods #{available_methods}"
      end

      def ensure_scope(scope)
        scope_map = {
          :base => Net::LDAP::SearchScope_BaseObject,
          :sub => Net::LDAP::SearchScope_WholeSubtree,
          :one => Net::LDAP::SearchScope_SingleLevel,
        }
        value = scope_map[scope || :sub]
        if value.nil?
          available_scopes = scope_map.keys.inspect
          raise ArgumentError, "#{scope.inspect} is not one of the available " +
                               "LDAP scope #{available_scopes}"
        end
        value
      end

      # Bind to LDAP with the given DN using any available SASL methods
      def sasl_bind(bind_dn, options={})
        return false unless bind_dn

        # Get all SASL mechanisms
        mechanisms = operation(options) do
          key = "supportedSASLMechanisms"
          root_dse([key])[key]
        end
        mechanisms ||= []

        sasl_mechanisms = options[:sasl_mechanisms] || @sasl_mechanisms
        sasl_mechanisms.each do |mechanism|
          next unless mechanisms.include?(mechanism)
          operation(options) do
            args = {
              :method => :sasl,
              :initial_credential => bind_dn,
              :mechanism => mechanism,
            }
            if need_credential_sasl_mechanism?(mechanism)
              args[:challenge_response] = Proc.new do |cred|
                password(cred, options)
              end
            end
            @connection.bind(args)
            return true if @connection.bound?
          end
        end
        false
      end

      # Bind to LDAP with the given DN and password
      def simple_bind(bind_dn, options={})
        return false unless bind_dn

        passwd = password(bind_dn, options)
        return false unless passwd

        begin
          operation do
            args = {
              :method => :simple,
              :username => bind_dn,
              :password => passwd,
            }
            @connection.bind(args).zero?
          end
        rescue Net::LDAP::LdapError
          @logger.debug {"Failed to bind as DN: #{bind_dn}"}
          false
        end
      end

      def parse_entries(entries)
        result = []
        entries.each do |type, key, attributes|
          mod_type = ensure_mod_type(type)
          attributes.each do |name, values|
            result << [mod_type, name, values]
          end
        end
        result
      end

      def ensure_mod_type(type)
        case type
        when :replace, :add
          type
        else
          raise ArgumentError, "unknown type: #{type}"
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
                  'Giving up trying to reconnect to LDAP server.'
          end

          @logger.debug {'Attempting to reconnect'}
          disconnect!

          # Reset the attempts if this was forced.
          options[:reconnect_attempts] = 0 if force
          options[:reconnect_attempts] += 1 if retry_limit >= 0
          begin
            connect(options)
            break
          rescue => detail
            @logger.error {"Reconnect to server failed: #{detail.exception}"}
            @logger.error {"Reconnect to server failed backtrace:\n" +
                            detail.backtrace.join("\n")}
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
    end
  end
end
