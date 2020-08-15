require 'active_ldap/adapter/base'

module ActiveLdap
  module Adapter
    class Base
      class << self
        def ldap_connection(options)
          require 'active_ldap/adapter/ldap_ext'
          Ldap.new(options)
        end
      end
    end

    class Ldap < Base
      module Method
        class Base
          def ssl?
            false
          end

          def start_tls?
            false
          end
        end

        class SSL < Base
          def connect(host, port, options={})
            LDAP::SSLConn.new(host, port, false)
          end

          def ssl?
            true
          end
        end

        class TLS < Base
          def connect(host, port, options={})
            connection = LDAP::Conn.new(host, port)
            if connection.get_option(LDAP::LDAP_OPT_PROTOCOL_VERSION) < 3
              connection.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
            end
            tls_options = options[:tls_options]
            if tls_options and LDAP.const_defined?(:LDAP_OPT_X_TLS_NEWCTX)
              tls_options.each do |key, value|
                case key
                when :verify_mode
                  case value
                  when :none, OpenSSL::SSL::SSL_VERIFY_NONE
                    connection.set_option(LDAP::LDAP_OPT_X_TLS_REQUIRE_CERT,
                                          LDAP::LDAP_OPT_X_TLS_NEVER)
                  when :peer, OpenSSL::SSL::SSL_VERIFY_PEER
                    connection.set_option(LDAP::LDAP_OPT_X_TLS_REQUIRE_CERT,
                                          LDAP::LDAP_OPT_X_TLS_DEMAND)
                  end
                when :verify_hostname
                  unless value
                    connection.set_option(LDAP::LDAP_OPT_X_TLS_REQUIRE_CERT,
                                          LDAP::LDAP_OPT_X_TLS_ALLOW)
                  end
                end
              end
              connection.set_option(LDAP::LDAP_OPT_X_TLS_NEWCTX, 0)
            end
            connection.start_tls
            connection
          end

          def start_tls?
            true
          end
        end

        class Plain < Base
          def connect(host, port, options={})
            LDAP::Conn.new(host, port)
          end
        end
      end

      def connect(options={})
        super do |host, port, method|
          uri = construct_uri(host, port, method.ssl?)
          with_start_tls = method.start_tls?
          info = {
            :uri => uri,
            :with_start_tls => with_start_tls,
            :tls_options => @tls_options,
          }
          connection = log("connect", info) do
            method.connect(host, port, :tls_options => @tls_options)
          end
          [connection, uri, with_start_tls]
        end
      end

      def unbind(options={})
        super do
          execute(:unbind)
        end
      end

      def bind(options={})
        super do
          @connection.error_message
        end
      end

      def bind_as_anonymous(options={})
        super do
          execute(:bind, :name => "bind: anonymous")
          true
        end
      end

      def search(options={})
        super(options) do |search_options|
          begin
            scope = search_options[:scope]
            info = search_options.merge(scope: scope_name(scope))
            execute(:search_full, info, search_options) do |entry|
              attributes = {}
              entry.attrs.each do |attr|
                value = entry.vals(attr)
                attributes[attr] = value if value
              end
              yield([entry.dn, attributes])
            end
          rescue RuntimeError
            if $!.message == "no result returned by search"
              @logger.debug do
                args = [
                  search_options[:filter],
                  search_options[:attributes].inspect,
                ]
                _("No matches: filter: %s: attributes: %s") % args
              end
            else
              raise
            end
          end
        end
      end

      def delete(targets, options={})
        super do |target|
          controls = options[:controls]
          info = {:dn => target}
          if controls
            info.merge!(:name => :delete, :controls => controls)
            execute(:delete_ext, info,
                    target, controls, [])
          else
            execute(:delete, info, target)
          end
        end
      end

      def add(dn, entries, options={})
        super do |_dn, _entries|
          controls = options[:controls]
          attributes = parse_entries(_entries)
          info = {:dn => _dn, :attributes => _entries}
          if controls
            info.merge!(:name => :add, :controls => controls)
            execute(:add_ext, info, _dn, attributes, controls, [])
          else
            execute(:add, info, _dn, attributes)
          end
        end
      end

      def modify(dn, entries, options={})
        super do |_dn, _entries|
          controls = options[:controls]
          attributes = parse_entries(_entries)
          info = {:dn => _dn, :attributes => _entries}
          if controls
            info.merge!(:name => :modify, :controls => controls)
            execute(:modify_ext, info, _dn, attributes, controls, [])
          else
            execute(:modify, info, _dn, attributes)
          end
        end
      end

      def modify_rdn(dn, new_rdn, delete_old_rdn, new_superior, options={})
        super do |_dn, _new_rdn, _delete_old_rdn, _new_superior|
          rename_available_p = @connection.respond_to?(:rename)
          if _new_superior and not rename_available_p
            raise NotImplemented.new(_("modify RDN with new superior"))
          end
          info = {
            :name => "modify: RDN",
            :dn => _dn,
            :new_rdn => _new_rdn,
            :new_superior => _new_superior,
            :delete_old_rdn => _delete_old_rdn
          }
          if rename_available_p
            execute(:rename, info,
                    _dn, _new_rdn, _new_superior, _delete_old_rdn, [], [])
          else
            execute(:modrdn, info, _dn, _new_rdn, _delete_old_rdn)
          end
        end
      end

      private
      def prepare_connection(options={})
        operation(options) do
          @connection.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
          @ldap_follow_referrals = follow_referrals?(options) ? 1 : 0
          @connection.set_option(LDAP::LDAP_OPT_REFERRALS,
                                 @ldap_follow_referrals)
        end
      end

      def execute(method, info=nil, *args, &block)
        begin
          name = (info || {}).delete(:name) || method
          @connection.set_option(LDAP::LDAP_OPT_REFERRALS,
                                 @ldap_follow_referrals)
          log(name, info) {@connection.send(method, *args, &block)}
        rescue LDAP::ResultError
          @connection.assert_error_code
          raise $!.message
        end
      end

      def ensure_method(method)
        normalized_method = method.to_s.downcase
        Method.constants.each do |name|
          if normalized_method == name.to_s.downcase
            return Method.const_get(name).new
          end
        end

        available_methods = Method.constants.collect do |name|
          name.downcase.to_sym.inspect
        end.join(", ")
        format = _("%s is not one of the available connect methods: %s")
        raise ConfigurationError, format % [method.inspect, available_methods]
      end

      def ensure_scope(scope)
        scope_map = {
          :base => LDAP::LDAP_SCOPE_BASE,
          :sub => LDAP::LDAP_SCOPE_SUBTREE,
          :one => LDAP::LDAP_SCOPE_ONELEVEL,
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
          LDAP::LDAP_SCOPE_BASE => :base,
          LDAP::LDAP_SCOPE_SUBTREE => :sub,
          LDAP::LDAP_SCOPE_ONELEVEL => :one,
        }[scope]
      end

      def sasl_bind(bind_dn, options={})
        super do |_bind_dn, mechanism, quiet|
          begin
            _bind_dn ||= ''
            sasl_quiet = @connection.sasl_quiet
            @connection.sasl_quiet = quiet unless quiet.nil?
            args = [_bind_dn, mechanism]
            credential = nil
            if need_credential_sasl_mechanism?(mechanism)
              credential = password(_bind_dn, options)
            end
            if @sasl_options
              credential ||= ""
              args.concat([credential, nil, nil, @sasl_options])
            else
              args << credential if credential
            end
            info = {
              :name => "bind: SASL", :dn => _bind_dn, :mechanism => mechanism
            }
            execute(:sasl_bind, info, *args)
            true
          ensure
            @connection.sasl_quiet = sasl_quiet
          end
        end
      end

      def simple_bind(bind_dn, options={})
        super do |_bind_dn, password|
          execute(:bind, {:dn => _bind_dn}, _bind_dn, password)
          true
        end
      end

      def parse_entries(entries)
        result = []
        entries.each do |type, key, attributes|
          mod_type = ensure_mod_type(type)
          binary = schema.attribute(key).binary?
          mod_type |= LDAP::LDAP_MOD_BVALUES if binary
          attributes.each do |name, values|
            additional_mod_type = 0
            if values.any? {|value| Ldif::Attribute.binary_value?(value)}
              additional_mod_type |= LDAP::LDAP_MOD_BVALUES
            end
            result << LDAP.mod(mod_type | additional_mod_type, name, values)
          end
        end
        result
      end

      def ensure_mod_type(type)
        case type
        when :replace, :add, :delete
          LDAP.const_get("LDAP_MOD_#{type.to_s.upcase}")
        else
          raise ArgumentError, _("unknown type: %s") % type
        end
      end
    end
  end
end
