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

      def initialize(host, port, method, timeout, follow_referrals)
        @host = host
        @port = port
        @method = method
        @timeout = timeout
        @context = nil
        @tls = nil
        @follow_referrals = follow_referrals
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

      def search(options)
        base = options[:base]
        scope = options[:scope]
        filter = options[:filter]
        attributes = options[:attributes]
        limit = options[:limit]
        use_paged_results = options[:use_paged_results]
        page_size = options[:page_size]

        controls = SearchControls.new
        controls.search_scope = scope

        controls.count_limit = limit if limit
        unless attributes.blank?
          controls.returning_attributes = attributes.to_java(:string)
        end

        page_cookie = nil
        if use_paged_results
          # https://devdocs.io/openjdk~8/javax/naming/ldap/pagedresultscontrol
          @context.set_request_controls([build_paged_results_control(page_size)])
        else
          @context.set_request_controls([])
        end

        escaped_base = escape_dn(base)

        loop do
          @context.search(escaped_base, filter, controls).each do |search_result|
            yield(build_raw_search_result(search_result))
          end

          break unless use_paged_results

          # Find the paged search cookie
          response_controls = @context.get_response_controls
          break unless response_controls
          response_controls.each do |response_control|
            next unless response_control.is_a?(PagedResultsResponseControl)
            page_cookie = response_control.get_cookie
            break
          end

          break unless page_cookie

          # Set paged results control so we can keep getting results.
          paged_results_control =
            build_paged_results_control(page_size, page_cookie)
          @context.set_request_controls([paged_results_control])
        end
      end

      def add(dn, records)
        attributes = BasicAttributes.new
        records.each do |record|
          attributes.put(record.to_java_attribute)
        end
        @context.set_request_controls([])
        @context.create_subcontext(escape_dn(dn), attributes)
      end

      def modify(dn, records)
        items = records.collect(&:to_java_modification_item)
        @context.set_request_controls([])
        @context.modify_attributes(escape_dn(dn), items.to_java(ModificationItem))
      end

      def modify_rdn(dn, new_rdn, delete_old_rdn)
        # should use mutex
        delete_rdn_key = "java.naming.ldap.deleteRDN"
        @context.set_request_controls([])
        begin
          @context.add_to_environment(delete_rdn_key, delete_old_rdn.to_s)
          @context.rename(escape_dn(dn), escape_dn(new_rdn))
        ensure
          @context.remove_from_environment(delete_rdn_key)
        end
      end

      def delete(dn)
        escaped_dn = escape_dn(dn)
        @context.set_request_controls([])
        @context.destroy_subcontext(escaped_dn)
      end

      private
      def setup_context(bind_dn, password, authentication)
        unbind
        environment = {
          Context::INITIAL_CONTEXT_FACTORY => "com.sun.jndi.ldap.LdapCtxFactory",
          Context::PROVIDER_URL => ldap_uri,
          'com.sun.jndi.ldap.connect.timeout' => (@timeout * 1000).to_i.to_s,
          'com.sun.jndi.ldap.read.timeout' => (@timeout * 1000).to_i.to_s,
          'java.naming.ldap.derefAliases' => 'never',
          'java.naming.referral' => @follow_referrals ? 'follow' : 'ignore',
        }
        context = InitialLdapContext.new(HashTable.new(environment), nil)
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

      def escape_dn(dn)
        javax.naming.ldap.LdapName.new(dn)
      rescue Java::JavaLang::IllegalArgumentException, Java::JavaxNaming::InvalidNameException
        dn
      end

      def build_paged_results_control(page_size, page_cookie=nil)
        PagedResultsControl.new(page_size, page_cookie, Control::CRITICAL)
      end

      def build_raw_search_result(search_result)
        attributes = {}
        search_result.attributes.get_all.each do |attribute|
          attributes[attribute.get_id] = attribute.get_all.collect do |value|
            value.is_a?(String) ? value : String.from_java_bytes(value)
          end
        end
        [search_result.name_in_namespace, attributes]
      end
    end
  end
end
