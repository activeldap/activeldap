require 'ldap'
require 'ldap/ldif'
require 'ldap/schema'

require 'activeldap/ldap'
require 'activeldap/schema'

require 'activeldap/adaptor/base'

class LDAP::Mod
  unless instance_method(:to_s).arity.zero?
    def to_s
      inspect
    end
  end

  alias_method :_initialize, :initialize
  def initialize(op, type, vals)
    if (LDAP::VERSION.split(/\./).collect {|x| x.to_i} <=> [0, 9, 7]) <= 0
      @op, @type, @vals = op, type, vals # to protect from GC
    end
    _initialize(op, type, vals)
  end
end

module ActiveLDAP
  module Adaptor
    class Ldap < Base
      module Method
        class SSL
          def connect(host, port)
            LDAP::SSLConn.new(host, port, false)
          end
        end

        class TLS
          def connect(host, port)
            LDAP::SSLConn.new(host, port, true)
          end
        end

        class Plain
          def connect(host, port)
            LDAP::Conn.new(host, port)
          end
        end
      end

      SCOPE = {
        :base => LDAP::LDAP_SCOPE_BASE,
        :sub => LDAP::LDAP_SCOPE_SUBTREE,
        :one => LDAP::LDAP_SCOPE_ONELEVEL,
      }

      def initialize(config={})
        super
        ensure_method
      end

      def connect(options={})
        @connection = @method.connect(@host, @port)
        operation(options) do
          @connection.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
        end
        bind(options)
      end

      def schema(options={})
        @schema ||= operation(options) do
          base = options[:base]
          attrs = options[:attrs]
          sec = options[:sec] || 0
          usec = options[:usec] || 0

          attrs ||= [
            'objectClasses',
            'attributeTypes',
            'matchingRules',
            'matchingRuleUse',
            'dITStructureRules',
            'dITContentRules',
            'nameForms',
            'ldapSyntaxes',
          ]
          key = 'subschemaSubentry'
          base ||= @connection.root_dse([key], sec, usec)[0][key][0]
          base ||= 'cn=schema'
          result = @connection.search2(base, LDAP::LDAP_SCOPE_BASE,
                                       '(objectClass=subschema)', attrs, false,
                                       sec, usec).first
          Schema.new(result)
        end
#       rescue
#         raise ConnectionError.new("Unable to retrieve schema from " +
#                                   "server (#{@method.class.downcase})")
      end

      def disconnect!(options={})
        return if @connection.nil?
        begin
          unbind(options)
        #rescue
        end
        @connection = nil
        # Make sure it is cleaned up
        # This causes Ruby/LDAP memory corruption.
        # GC.start
      end

      # Attempts to reconnect up to the number of times allowed
      # If forced, try once then fail with ConnectionError if not connected.
      def reconnect(force=false)
        connected = false
        until connected
          unless can_reconnect?
            raise ConnectionError,
                  'Giving up trying to reconnect to LDAP server.'
          end

          @logger.debug {'Attempting to reconnect'}
          disconnect!

          # Reset the attempts if this was forced.
          @reconnect_attempts = 0 if force
          @reconnect_attempts += 1 if @retry_limit >= 0
          begin
            connect
            connected = true
            @reconnect_attempts = 0
            next
          rescue => detail
            @logger.error {"Reconnect to server failed: #{detail.exception}"}
            @logger.error {"Reconnect to server failed backtrace: " +
                            detail.backtrace.join("\n")}
            # Do not loop if forced
            raise ConnectionError, detail.message if force
          end

          # Sleep before looping
          sleep @retry_wait
        end

        true
      end

      def unbind(options={})
        return unless bound?
        operation(options) do
          @connection.unbind
        end
      end

      def bind(options={})
        if @bind_format
          bind_dn = @bind_format % @user
        else
          bind_dn = nil
        end
        # Rough bind loop:
        # Attempt 1: SASL if available
        # Attempt 2: SIMPLE with credentials if password block
        # Attempt 3: SIMPLE ANONYMOUS if 1 and 2 fail (or pwblock returns '')
        if @try_sasl and sasl_bind(bind_dn, options)
          @logger.info {'Bound SASL'}
        elsif simple_bind(bind_dn, options)
          @logger.info {'Bound simple'}
        elsif @allow_anonymous and bind_as_anonymous(options)
          @logger.info {'Bound anonymous'}
        else
          raise *LDAP::err2exception(@connection.err) if @connection.err != 0
          raise AuthenticationError, 'All authentication methods exhausted.'
        end

        bound?
      end

      def bind_as_anonymous(options={})
        @logger.info {"Attempting anonymous authentication"}
        operation(options) do
          @connection.bind
          true
        end
      end

      def connecting?
        not @connection.nil?
      end

      def bound?
        @connection.bound?
      end

      # search
      #
      # Wraps Ruby/LDAP connection.search to make it easier to search for
      # specific data without cracking open Base.connection
      def search(options={})
        filter = options[:filter] || 'objectClass=*'
        attrs = options[:attrs] || []
        scope = ensure_scope(options[:scope])
        base = options[:base]
        limit = options[:limit] || 0
        limit = nil if limit <= 0

        values = []
        attrs = attrs.to_a # just in case

        begin
          operation(options) do
            i = 0
            @connection.search(base, scope, filter, attrs) do |m|
              i += 1
              attributes = {}
              m.attrs.each do |attr|
                attributes[attr] = m.vals(attr)
              end
              value = [m.dn, attributes]
              value = yield(value) if block_given?
              values.push(value)
              break if limit and limit >= i
            end
          end
        rescue LDAP::Error
          # Do nothing on failure
          @logger.debug {"Ignore error #{$!.class}(#{$!.message}) " +
                         "for #{filter} and attrs #{attrs.inspect}"}
        rescue RuntimeError
          if $!.message == "no result returned by search"
            @logger.debug {"No matches for #{filter} and attrs " +
                           "#{attrs.inspect}"}
          else
            raise
          end
        end

        values
      end

      def to_ldif(dn, attributes)
        ldif = LDAP::LDIF.to_ldif("dn", [dn.dup])
        attributes.sort_by do |key, value|
          key
        end.each do |key, values|
          ldif << LDAP::LDIF.to_ldif(key, values)
        end
        ldif
      end

      def load(ldifs, options={})
        operation(options) do
          ldifs.split(/(?:\r?\n){2,}/).each do |ldif|
            LDAP::LDIF.parse_entry(ldif).send(@connection)
          end
        end
      end

      def delete(targets, options={})
        targets = [targets] unless targets.is_a?(Array)
        return if targets.empty?
        operation(options) do
          targets.each do |target|
            @connection.delete(target)
          end
        end
      end

      def add(dn, entries, options={})
        begin
          operation(options) do
            @connection.add(dn, parse_entries(entries))
          end
        rescue LDAP::NoSuchObject
          raise EntryNotFound, "No such entry: #{dn}"
        rescue LDAP::InvalidDnSyntax
          raise DistinguishedNameInvalid.new(dn)
        rescue LDAP::AlreadyExists
          raise EntryAlreadyExist, "#{$!.message}: #{dn}"
        rescue LDAP::StrongAuthRequired
          raise StrongAuthenticationRequired, "#{$!.message}: #{dn}"
        rescue LDAP::ObjectClassViolation
          raise RequiredAttributeMissed, "#{$!.message}: #{dn}"
        rescue LDAP::UnwillingToPerform
          raise UnwillingToPerform, "#{$!.message}: #{dn}"
        end
      end

      def modify(dn, entries, options={})
        begin
          operation(options) do
            @connection.modify(dn, parse_entries(entries))
          end
        rescue LDAP::UndefinedType
          raise
        rescue LDAP::ObjectClassViolation
          raise RequiredAttributeMissed, "#{$!.message}: #{dn}"
        end
      end

      def reconnect_if_need
        reconnect if !connecting? and can_reconnect?
      end

      # Determine if we have exceed the retry limit or not.
      # True is reconnecting is allowed - False if not.
      def can_reconnect?
        @retry_limit < 0 or @reconnect_attempts < (@retry_limit - 1)
      end

      private
      def operation(options={}, &block)
        reconnect_if_need
        try_reconnect = !options.has_key?(:try_reconnect) ||
                           options[:try_reconnect]
        with_timeout(try_reconnect) do
          begin
            block.call
          rescue LDAP::ResultError
            raise *LDAP::err2exception(@connection.err) if @connection.err != 0
            raise
          end
        end
      end

      def with_timeout(try_reconnect=true, &block)
        begin
          super
        rescue LDAP::ServerDown => e
          @logger.error {"#{e.class} exception occurred in with_timeout block"}
          @logger.error {"Exception message: #{e.message}"}
          @logger.error {"Exception backtrace: #{e.backtrace}"}
          retry if try_reconnect and reconnect
          raise ConnectionError.new(e.message)
        end
      end

      def ensure_method
        Method.constants.each do |name|
          if @method.to_s.downcase == name.downcase
            @method = Method.const_get(name).new
            return
          end
        end

        available_methods = Method.constants.collect do |name|
          name.downcase.to_sym
        end.join(", ")
        raise ConfigurationError,
                "#{@method} is not one of the available connect " +
                " methods #{available_methods}"
      end

      def ensure_scope(scope)
        value = SCOPE[scope || :sub]
        if value.nil?
          available_scopes = SCOPE.keys.collect do |scope|
            scope.inspect
          end.join(", ")
          raise ArgumentError, "#{scope} is not one of the available " +
                               "LDAP scope #{available_scopes}"
        end
        value
      end

      # Bind to LDAP with the given DN using any available SASL methods
      def sasl_bind(bind_dn, options={})
        # Get all SASL mechanisms
        #
        mechanisms = nil
        exc = ConnectionError.new('Root DSE query failed')
        mechanisms = operation do
          @connection.root_dse[0]['supportedSASLMechanisms']
        end

        # Use GSSAPI if available
        # Currently only GSSAPI is supported with Ruby/LDAP from
        # http://caliban.org/files/redhat/RPMS/i386/ruby-ldap-0.8.2-4.i386.rpm
        # TODO: Investigate further SASL support
        return false unless (mechanisms || []).include?('GSSAPI')
        operation do
          @connection.sasl_quiet = @sasl_quiet unless @sasl_quit.nil?
          @connection.sasl_bind(bind_dn, 'GSSAPI')
          true
        end
      end

      # Bind to LDAP with the given DN and password
      def simple_bind(bind_dn, options={})
        # Bail if we have no password or password block
        if @password.nil? and @password_block.nil?
          @logger.error {'Skipping simple bind: ' +
                         '@password_block and @password options are empty.'}
          return false
        end

        if @password
          password = @password
        else
          # TODO: Give a warning to reconnect users with password clearing
          # Get the passphrase for the first time, or anew if we aren't storing
          unless @password_block.respond_to?(:call)
            @logger.error {'Skipping simple bind: ' +
                           '@password_block not nil or Proc object. Ignoring.'}
            return false
          end
          password = @password_block.call
        end

        # Store the password for quick reference later
        @password = @store_password ? password : nil

        begin
          operation do
            @connection.bind(bind_dn, password)
            true
          end
        rescue LDAP::InvalidDnSyntax
          @logger.debug {"DN is invalid: #{bind_dn}"}
          raise DistinguishedNameInvalid.new(bind_dn)
        rescue LDAP::InvalidCredentials
          false
        end
      end

      def parse_entries(entries)
        result = []
        entries.each do |type, key, attributes|
          mod_type = ensure_mod_type(type)
          binary = schema.binary?(key)
          mod_type |= LDAP::LDAP_MOD_BVALUES if binary
          attributes.each do |name, values|
            next if binary and values.empty?
            result << LDAP.mod(mod_type, name, values)
          end
        end
        result
      end

      def ensure_mod_type(type)
        case type
        when :replace, :add
          LDAP.const_get("LDAP_MOD_#{type.to_s.upcase}")
        else
          raise ArgumentError, "unknown type: #{type}"
        end
      end
    end
  end
end
