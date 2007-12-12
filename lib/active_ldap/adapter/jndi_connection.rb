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
      InitialDirContext = javax.naming.directory.InitialDirContext
      SearchControls = javax.naming.directory.SearchControls
      ModificationItem = javax.naming.directory.ModificationItem
      BasicAttributes = javax.naming.directory.BasicAttributes
      Context = javax.naming.Context

      NamingException = javax.naming.NamingException
      NameNotFoundException = javax.naming.NameNotFoundException

      class ModifyRecord
        DirContext = javax.naming.directory.DirContext
        BasicAttribute = javax.naming.directory.BasicAttribute

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
      end

      def unbind
        @context.close if @context
        @context = nil
      end

      def bound?
        not @context.nil?
      end

      def sasl_bind(bind_dn, mechanism, quiet)
      end

      def simple_bind(bind_dn, password)
        @context = make_context(bind_dn, password)
      end

      def bind_as_anonymous
        @context = make_context(nil, nil)
      end

      def search(base, scope, filter, attrs, limit, callback, &block)
        controls = SearchControls.new
        controls.search_scope = scope

        if attrs && !attrs.empty?
          controls.returning_attributes = attrs.to_java(:string)
        end

        i = 0
        @context.search(base, filter, controls).each do |result|
          i += 1
          attributes = {}
          result.attributes.get_all.each do |attribute|
            attributes[attribute.get_id] = attribute.get_all.collect do |value|
              value.is_a?(String) ? value : String.from_java_bytes(value)
            end
          end
          callback.call([result.name_in_namespace, attributes], block)
          break if limit and limit <= i
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

      def delete(dn)
        @context.destroy_subcontext(dn)
      end

      private
      def make_context(bind_dn, password)
        environment = {
          Context::INITIAL_CONTEXT_FACTORY => "com.sun.jndi.ldap.LdapCtxFactory",
          Context::PROVIDER_URL => ldap_uri,
        }
        environment[Context::SECURITY_PRINCIPAL] = bind_dn if bind_dn
        environment[Context::SECURITY_CREDENTIALS] = password if password
        environment = HashTable.new(environment)
        InitialDirContext.new(environment)
      end

      def ldap_uri
        protocol = @method == :ssl ? "ldaps" : "ldap"
        "#{protocol}://#{@host}:#{@port}/"
      end
    end
  end
end
