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
          uri = construct_uri(host, port, method == :ssl)
          with_start_tls = method == :start_tls
          info = {:uri => uri, :with_start_tls => with_start_tls}
          [log("connect", info) {JndiConnection.new(host, port, method)},
           uri, with_start_tls]
        end
      end

      def unbind(options={})
        super do
          execute(:unbind)
        end
      end

      def bind_as_anonymous(options={})
        super do
          execute(:bind_as_anonymous, :name => "bind: anonymous")
          true
        end
      end

      def search(options={}, &block)
        super(options) do |base, scope, filter, attrs, limit, callback|
          info = {
            :base => base, :scope => scope_name(scope), :filter => filter,
            :attributes => attrs,
          }
          execute(:search, info,
                  base, scope, filter, attrs, limit, callback, &block)
        end
      end

      def delete(targets, options={})
        super do |target|
          execute(:delete, {:dn => target}, target)
        end
      end

      def add(dn, entries, options={})
        super do |_dn, _entries|
          info = {:dn => _dn, :attributes => _entries}
          execute(:add, info, _dn, parse_entries(_entries))
        end
      end

      def modify(dn, entries, options={})
        super do |_dn, _entries|
          info = {:dn => _dn, :attributes => _entries}
          execute(:modify, info, _dn, parse_entries(_entries))
        end
      end

      def modify_rdn(dn, new_rdn, delete_old_rdn, new_superior, options={})
        super do |_dn, _new_rdn, _delete_old_rdn, _new_superior|
          info = {
            :name => "modify: RDN",
            :dn => _dn, :new_rdn => _new_rdn, :delete_old_rdn => _delete_old_rdn,
          }
          execute(:modify_rdn, info, _dn, _new_rdn, _delete_old_rdn)
        end
      end

      private
      def execute(method, info=nil, *args, &block)
        name = (info || {}).delete(:name) || method
        log(name, info) {@connection.send(method, *args, &block)}
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
          :base => JndiConnection::Scope::OBJECT,
          :one => JndiConnection::Scope::ONE_LEVEL,
          :sub => JndiConnection::Scope::SUBTREE,
        }
        value = scope_map[scope || :sub]
        if value.nil?
          available_scopes = scope_map.keys.inspect
          format = _("%s is not one of the available LDAP scope: %s")
          raise ArgumentError, format % [scope.inspect, available_scopes]
        end
        value
      end

      def scope_name(scope)
        {
          JndiConnection::Scope::OBJECT => :base,
          JndiConnection::Scope::ONE_LEVEL => :one,
          JndiConnection::Scope::SUBTREE => :sub,
        }[scope]
      end

      def sasl_bind(bind_dn, options={})
        super do |_bind_dn, mechanism, quiet|
          info = {
            :name => "bind: SASL",
            :dn => _bind_dn,
            :mechanism => mechanism
          }
          execute(:sasl_bind, info, _bind_dn, mechanism, quiet)
          true
        end
      end

      def simple_bind(bind_dn, options={})
        super do |_bind_dn, password|
          info = {:name => "bind", :dn => _bind_dn}
          execute(:simple_bind, info, _bind_dn, password)
          true
        end
      end

      def parse_entries(entries)
        result = []
        entries.each do |type, key, attributes|
          mod_type = ensure_mod_type(type)
          binary = schema.attribute(key).binary?
          attributes.each do |name, values|
            real_binary = binary
            if values.any? {|value| Ldif::Attribute.binary_value?(value)}
              real_binary = true
            end
            result << JndiConnection::ModifyRecord.new(mod_type, name,
                                                       values, real_binary)
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
