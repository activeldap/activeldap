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
      PagedResultsControl = ldap.PagedResultsControl
      PagedResultsResponseControl = ldap.PagedResultsResponseControl

      CommunicationException = naming.CommunicationException
      ServiceUnavailableException = naming.ServiceUnavailableException
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

      def initialize(host, port, method, timeout)
        @host = host
        @port = port
        @method = method
        @timeout = timeout
        @mod_context = nil
        @search_context = nil
        @tls = nil
        @search_tls = nil
      end

      def unbind
        @tls.close if @tls
        @tls = nil
        @search_tls.close if @search_tls
        @search_tls = nil
        @mod_context.close if @mod_context
        @mod_context = nil
        @search_context.close if @search_context
        @search_context = nil
      end

      def bound?
        not @mod_context.nil?
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

      def search(base, scope, filter, attrs, limit, use_paged_results, page_size)
        controls = SearchControls.new
        controls.search_scope = scope

        controls.count_limit = limit if limit
        unless attrs.blank?
          controls.returning_attributes = attrs.to_java(:string)
        end

        escaped_base = escape_dn(base)

        if use_paged_results
          # https://devdocs.io/openjdk~8/javax/naming/ldap/pagedresultscontrol
          page_cookie = nil
          @search_context.set_request_controls([PagedResultsControl.new(page_size, Control::CRITICAL)])
        else
          @search_context.set_request_controls([])
        end

        loop do
          @search_context.search(escaped_base, filter, controls).each do |result|
            attributes = {}
            result.attributes.get_all.each do |attribute|
              attributes[attribute.get_id] = attribute.get_all.collect do |value|
                value.is_a?(String) ? value : String.from_java_bytes(value)
              end
            end

            yield([result.name_in_namespace, attributes])
          end

          break unless use_paged_results

          # Find the paged search cookie
          if res_controls = @search_context.get_response_controls
            res_controls.each do |res_control|
              next unless res_control.is_a? PagedResultsResponseControl

              page_cookie = res_control.get_cookie
              break
            end
          end

          break unless page_cookie

          # Set paged results control so we can keep getting results.
          @search_context.set_request_controls(
            [PagedResultsControl.new(page_size, page_cookie, Control::CRITICAL)]
          )
        end
      end

      def add(dn, records)
        attributes = BasicAttributes.new
        records.each do |record|
          attributes.put(record.to_java_attribute)
        end
        escaped_dn = escape_dn(dn)
        @mod_context.create_subcontext(escaped_dn, attributes)
      end

      def modify(dn, records)
        escaped_dn = escape_dn(dn)
        items = records.collect(&:to_java_modification_item)
        @mod_context.modify_attributes(escaped_dn, items.to_java(ModificationItem))
      end

      def modify_rdn(dn, new_rdn, delete_old_rdn)
        escaped_dn = escape_dn(dn)
        # should use mutex
        delete_rdn_key = "java.naming.ldap.deleteRDN"
        @mod_context.add_to_environment(delete_rdn_key, delete_old_rdn.to_s)
        @mod_context.rename(escaped_dn, new_rdn)
      ensure
        @mod_context.remove_from_environment(delete_rdn_key)
      end

      def delete(dn)
        escaped_dn = escape_dn(dn)
        @mod_context.destroy_subcontext(escaped_dn)
      end

      private
      def setup_context(bind_dn, password, authentication)
        unbind
        environment = {
          Context::INITIAL_CONTEXT_FACTORY => "com.sun.jndi.ldap.LdapCtxFactory",
          Context::PROVIDER_URL => ldap_uri,
          'com.sun.jndi.ldap.connect.timeout' => (@timeout * 1000).to_i.to_s,
          'com.sun.jndi.ldap.read.timeout' => (@timeout * 1000).to_i.to_s,
        }
        environment = HashTable.new(environment)

        # Create a separate context for searching so we can add paged results control if available.
        @mod_context = InitialLdapContext.new(environment, nil)
        @search_context = InitialLdapContext.new(environment, nil)

        if @method == :start_tls
          @tls = @mod_context.extended_operation(StartTlsRequest.new)
          @tls.negotiate
          @search_tls = @search_context.extended_operation(StartTlsRequest.new)
          @search_tls.negotiate
        end

        @mod_context.add_to_environment(Context::SECURITY_AUTHENTICATION, authentication)
        @search_context.add_to_environment(Context::SECURITY_AUTHENTICATION, authentication)

        if bind_dn
          @mod_context.add_to_environment(Context::SECURITY_PRINCIPAL, bind_dn)
          @search_context.add_to_environment(Context::SECURITY_PRINCIPAL, bind_dn)
        end

        if password
          @mod_context.add_to_environment(Context::SECURITY_CREDENTIALS, password)
          @search_context.add_to_environment(Context::SECURITY_CREDENTIALS, password)
        end

        @mod_context.reconnect(nil)
        @search_context.reconnect(nil)
      end

      def ldap_uri
        protocol = @method == :ssl ? "ldaps" : "ldap"
        "#{protocol}://#{@host}:#{@port}/"
      end

      def escape_dn(dn)
        parsed_dn = nil
        begin
          parsed_dn = DN.parse(dn)
        rescue DistinguishedNameInvalid
          return dn
        end

        escaped_rdns = parsed_dn.rdns.collect do |rdn|
          escaped_rdn_strings = rdn.collect do |key, value|
            escaped_value = DN.escape_value(value)
            # We may need to escape the followings too:
            #   * ,
            #   * =
            #   * +
            #   * <
            #   * >
            #   * #
            #   * ;
            #
            # See javax.naming.ldap.Rdn.unescapeValue()
            escaped_value = escaped_value.gsub(/\\\\/) do
              "\\5C"
            end
            "#{key}=#{escaped_value}"
          end
          escaped_rdn_strings.join("+")
        end
        escaped_rdns.join(",")
      end
    end
  end
end
