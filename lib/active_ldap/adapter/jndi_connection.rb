require 'java'

java.util.Enumeration.module_eval do
  include Enumerable

  def each
    while has_more_elements
      yield(next_element)
    end
  end
end

module ActiveLdap
  module Adapter
    class JndiConnection
      HashTable = java.util.Hashtable
      naming = javax.naming
      directory = naming.directory
      ldap = naming.ldap
      InitialDirContext = directory.InitialDirContext
      InitialLdapContext = ldap.InitialLdapContext
      SearchControls = directory.SearchControls
      ModificationItem = directory.ModificationItem
      BasicAttributes = directory.BasicAttributes
      Context = naming.Context
      StartTlsRequest = ldap.StartTlsRequest
      Control = ldap.Control

      CommunicationException = naming.CommunicationException
      NamingException = naming.NamingException
      NameNotFoundException = naming.NameNotFoundException

      module Scope
        OBJECT = SearchControls::OBJECT_SCOPE
        ONE_LEVEL = SearchControls::ONELEVEL_SCOPE
        SUBTREE = SearchControls::SUBTREE_SCOPE
      end

      class ModifyRecord
        directory = javax.naming.directory
        DirContext = directory.DirContext
        BasicAttribute = directory.BasicAttribute

        ADD_ATTRIBUTE = DirContext::ADD_ATTRIBUTE
        REPLACE_ATTRIBUTE = DirContext::REPLACE_ATTRIBUTE
        REMOVE_ATTRIBUTE = DirContext::REMOVE_ATTRIBUTE

        attr_reader :type, :name, :values
        def initialize(type, name, values, binary)
          @type = self.class.const_get("#{type.to_s.upcase}_ATTRIBUTE")
          @name = name
          @values = values
          @binary = binary
        end

        def binary?
          @binary
        end

        def to_java_modification_item
          ModificationItem.new(@type, to_java_attribute)
        end

        def to_java_attribute
          attribute = BasicAttribute.new(@name)
          values = @values
          values = values.collect(&:to_java_bytes) if binary?
          values.each do |value|
            attribute.add(value)
          end
          attribute
        end
      end

      def initialize(host, port, method)
        @host = host
        @port = port
        @method = method
        @context = nil
        @tls = nil
      end

      def unbind
        @tls.close if @tls
        @tls = nil
        @context.close if @context
        @context = nil
      end

      def bound?
        not @context.nil?
      end

      def sasl_bind(bind_dn, mechanism, quiet)
        setup_context(bind_dn, password, mechanism)
        bound?
      end

      def simple_bind(bind_dn, password)
        setup_context(bind_dn, password, "simple")
        bound?
      end

      def bind_as_anonymous
        setup_context(nil, nil, "none")
        bound?
      end

      def search(base, scope, filter, attrs, limit)
        controls = SearchControls.new
        controls.search_scope = scope

        controls.count_limit = limit if limit
        unless attrs.blank?
          controls.returning_attributes = attrs.to_java(:string)
        end

        @context.search(base, filter, controls).each do |result|
          attributes = {}
          result.attributes.get_all.each do |attribute|
            attributes[attribute.get_id] = attribute.get_all.collect do |value|
              value.is_a?(String) ? value : String.from_java_bytes(value)
            end
          end
          yield([result.name_in_namespace, attributes])
        end
      end

      def add(dn, records)
        attributes = BasicAttributes.new
        records.each do |record|
          attributes.put(record.to_java_attribute)
        end
        @context.create_subcontext(dn, attributes)
      end

      def modify(dn, records)
        items = records.collect(&:to_java_modification_item)
        @context.modify_attributes(dn, items.to_java(ModificationItem))
      end

      def modify_rdn(dn, new_rdn, delete_old_rdn)
        # should use mutex
        delete_rdn_key = "java.naming.ldap.deleteRDN"
        @context.add_to_environment(delete_rdn_key, delete_old_rdn.to_s)
        @context.rename(dn, new_rdn)
      ensure
        @context.remove_from_environment(delete_rdn_key)
      end

      def delete(dn)
        @context.destroy_subcontext(dn)
      end

      private
      def setup_context(bind_dn, password, authentication)
        unbind
        environment = {
          Context::INITIAL_CONTEXT_FACTORY => "com.sun.jndi.ldap.LdapCtxFactory",
          Context::PROVIDER_URL => ldap_uri,
        }
        environment = HashTable.new(environment)
        context = InitialLdapContext.new(environment, nil)
        if @method == :start_tls
          @tls = context.extended_operation(StartTlsRequest.new)
          @tls.negotiate
        end
        context.add_to_environment(Context::SECURITY_AUTHENTICATION,
                                   authentication)
        if bind_dn
          context.add_to_environment(Context::SECURITY_PRINCIPAL, bind_dn)
        end
        if password
          context.add_to_environment(Context::SECURITY_CREDENTIALS, password)
        end
        context.reconnect(nil)
        @context = context
      end

      def ldap_uri
        protocol = @method == :ssl ? "ldaps" : "ldap"
        "#{protocol}://#{@host}:#{@port}/"
      end
    end
  end
end
