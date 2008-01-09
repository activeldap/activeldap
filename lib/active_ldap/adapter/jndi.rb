require 'active_ldap/adapter/base'

module ActiveLdap
  module Adapter
    class Base
      class << self
        def jndi_connection(options)
          require 'active_ldap/adapter/jndi_connection'
          Jndi.new(options)
        end
      end
    end

    class Jndi < Base
      METHOD = {
        :ssl => :ssl,
        :tls => :start_tls,
        :plain => nil,
      }

      def connect(options={})
        super do |host, port, method|
          @connection = JndiConnection.new(host, port, method)
        end
      end

      def unbind(options={})
        return unless bound?
        operation(options) do
          execute(:unbind)
        end
      end

      def bind_as_anonymous(options={})
        super do
          execute(:bind_as_anonymous)
        end
      end

      def bound?
        connecting? and @connection.bound?
      end

      def search(options={}, &block)
        super(options) do |base, scope, filter, attrs, limit, callback|
          execute(:search, base, scope, filter, attrs, limit, callback, &block)
        end
      end

      def delete(targets, options={})
        super do |target|
          execute(:delete, target)
        end
      end

      def add(dn, entries, options={})
        super do |dn, entries|
          execute(:add, dn, parse_entries(entries))
        end
      end

      def modify(dn, entries, options={})
        super do |dn, entries|
          execute(:modify, dn, parse_entries(entries))
        end
      end

      def modify_rdn(dn, new_rdn, delete_old_rdn, new_superior, options={})
        super do |dn, new_rdn, delete_old_rdn, new_superior|
          execute(:modify_rdn, dn, new_rdn, delete_old_rdn)
        end
      end

      private
      def execute(method, *args, &block)
        @connection.send(method, *args, &block)
      rescue JndiConnection::NamingException
        if /\[LDAP: error code (\d+) - ([^\]]+)\]/ =~ $!.to_s
          message = $2
          klass = LdapError::ERRORS[Integer($1)]
          klass ||= ActiveLdap::LdapError
          raise klass, message
        end
        raise
      end

      def ensure_method(method)
        method ||= "plain"
        normalized_method = method.to_s.downcase.to_sym
        return METHOD[normalized_method] if METHOD.has_key?(normalized_method)

        available_methods = METHOD.keys.collect {|m| m.inspect}.join(", ")
        format = _("%s is not one of the available connect methods: %s")
        raise ConfigurationError, format % [method.inspect, available_methods]
      end

      def ensure_scope(scope)
        scope_map = {
          :base => 0,
          :one => 1,
          :sub => 2,
        }
        value = scope_map[scope || :sub]
        if value.nil?
          available_scopes = scope_map.keys.inspect
          format = _("%s is not one of the available LDAP scope: %s")
          raise ArgumentError, format % [scope.inspect, available_scopes]
        end
        value
      end

      def sasl_bind(bind_dn, options={})
        super do |bind_dn, mechanism, quiet|
          @connection.sasl_bind(bind_dn, mechanism, quiet)
        end
      end

      def simple_bind(bind_dn, options={})
        super do |bind_dn, passwd|
          @connection.simple_bind(bind_dn, passwd)
        end
      end

      def parse_entries(entries)
        result = []
        entries.each do |type, key, attributes|
          mod_type = ensure_mod_type(type)
          binary = schema.attribute(key).binary?
          attributes.each do |name, values|
            result << JndiConnection::ModifyRecord.new(mod_type, name,
                                                       values, binary)
          end
        end
        result
      end

      def ensure_mod_type(type)
        case type
        when :replace, :add
          type
        when :delete
          :remove
        else
          raise ArgumentError, _("unknown type: %s") % type
        end
      end
    end
  end
end
