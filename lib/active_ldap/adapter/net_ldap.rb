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
        super do |host, port, method|
          config = {
            :host => host,
            :port => port,
            :encryption => {:method => method},
          }
          Net::LDAP::Connection.new(config)
        end
      end

      def unbind(options={})
        @bound = false
      end

      def bind(options={})
        @bound = false
        begin
          super
        rescue Net::LDAP::LdapError
          raise AuthenticationError, $!.message
        end
      end

      def bind_as_anonymous(options={})
        super do
          @bound = false
          execute(:bind, :method => :anonymous)
          @bound = true
        end
      end

      def bound?
        connecting? and @bound
      end

      def search(options={}, &block)
        super(options) do |base, scope, filter, attrs, limit, callback|
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
            callback.call([entry.dn, attributes], block)
          end
        end
      end

      def to_ldif(dn, attributes)
        entry = Net::LDAP::Entry.new(dn.dup)
        attributes.each do |key, values|
          entry[key] = values.flatten
        end
        entry.to_ldif
      end

      def load(ldifs, options={})
        super do |ldif|
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

      def delete(targets, options={})
        super do |target|
          execute(:delete, :dn => target)
        end
      end

      def add(dn, entries, options={})
        super do |dn, entries|
          attributes = {}
          entries.each do |type, key, attrs|
            attrs.each do |name, values|
              attributes[name] = values
            end
          end
          execute(:add, :dn => dn, :attributes => attributes)
        end
      end

      def modify(dn, entries, options={})
        super do |dn, entries|
          execute(:modify,
                  :dn => dn,
                  :operations => parse_entries(entries))
        end
      end

      private
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

      def root_dse(attrs, options={})
        search(:base => "",
               :scope => :base,
               :attributes => attrs).collect do |dn, attributes|
          attributes
        end
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

      def sasl_bind(bind_dn, options={})
        super do |bind_dn, mechanism, quiet|
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
          @bound = false
          execute(:bind, args)
          @bound = true
        end
      end

      def simple_bind(bind_dn, options={})
        super do |bind_dn, passwd|
          args = {
            :method => :simple,
            :username => bind_dn,
            :password => passwd,
          }
          @bound = false
          execute(:bind, args)
          @bound = true
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
    end
  end
end
