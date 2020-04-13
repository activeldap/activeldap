require "ldap"
require "ldap/ldif"
require "ldap/schema"
require "ldap/control"

module LDAP
  unless const_defined?(:LDAP_OPT_ERROR_NUMBER)
    LDAP_OPT_ERROR_NUMBER = 0x0031
  end

  class Mod
    unless instance_method(:to_s).arity.zero?
      alias_method :original_to_s, :to_s
      def to_s
        inspect
      end
    end

    alias_method :_initialize, :initialize
    def initialize(op, type, vals)
      if (VERSION.split(/\./).collect {|x| x.to_i} <=> [0, 9, 7]) <= 0
        @op, @type, @vals = op, type, vals # to protect from GC
      end
      _initialize(op, type, vals)
    end
  end

  IMPLEMENT_SPECIFIC_ERRORS = {}
  {
    0x51 => "SERVER_DOWN",
    0x52 => "LOCAL_ERROR",
    0x53 => "ENCODING_ERROR",
    0x54 => "DECODING_ERROR",
    0x55 => "TIMEOUT",
    0x56 => "AUTH_UNKNOWN",
    0x57 => "FILTER_ERROR",
    0x58 => "USER_CANCELLED",
    0x59 => "PARAM_ERROR",
    0x5a => "NO_MEMORY",

    0x5b => "CONNECT_ERROR",
    0x5c => "NOT_SUPPORTED",
    0x5d => "CONTROL_NOT_FOUND",
    0x5e => "NO_RESULTS_RETURNED",
    0x5f => "MORE_RESULTS_TO_RETURN",
    0x60 => "CLIENT_LOOP",
    0x61 => "REFERRAL_LIMIT_EXCEEDED",
  }.each do |code, name|
    IMPLEMENT_SPECIFIC_ERRORS[code] =
      ActiveLdap::LdapError.define(code, name, self)
  end

  class Conn
    begin
      instance_method(:search_ext)
      @@have_search_ext = true
    rescue NameError
      @@have_search_ext = false
    end

    def search_full(options, &block)
      base              = options[:base]
      scope             = options[:scope]
      filter            = options[:filter]
      attributes        = options[:attributes]
      limit             = options[:limit] || 0
      use_paged_results = options[:use_paged_results]
      page_size         = options[:page_size]
      if @@have_search_ext
        if use_paged_results
          paged_search(base,
                       scope,
                       filter,
                       attributes,
                       limit,
                       page_size,
                       &block)
        else
          search_ext(base,
                     scope,
                     filter,
                     attributes,
                     false,
                     nil,
                     nil,
                     0,
                     0,
                     limit,
                     &block)
        end
      else
        i = 0
        search(base, scope, filter, attributes) do |entry|
          i += 1
          block.call(entry)
          break if 0 < limit and limit <= i
        end
      end
    end

    def failed?
      not error_code.zero?
    end

    def error_code
      code = err
      code = get_option(LDAP_OPT_ERROR_NUMBER) if code.zero?
      code
    end

    def error_message
      if failed?
        LDAP.err2string(error_code)
      else
        nil
      end
    end

    def assert_error_code
      return unless failed?
      code = error_code
      message = error_message
      klass = ActiveLdap::LdapError::ERRORS[code]
      klass ||= IMPLEMENT_SPECIFIC_ERRORS[code]
      if klass.nil? and message == "Can't contact LDAP server"
        klass = ActiveLdap::ConnectionError
      end
      klass ||= ActiveLdap::LdapError
      raise klass, message
    end

    private
    def find_paged_results_control(controls)
      controls.find do |control|
        control.oid == LDAP::LDAP_CONTROL_PAGEDRESULTS
      end
    end

    def paged_search(base, scope, filter, attributes, limit, page_size, &block)
      cookie = ""
      critical = true
      loop do
        ber_string = LDAP::Control.encode(page_size, cookie)
        control = LDAP::Control.new(LDAP::LDAP_CONTROL_PAGEDRESULTS,
                                    ber_string,
                                    critical)
        search_ext(base,
                   scope,
                   filter,
                   attributes,
                   false,
                   [control],
                   nil,
                   0,
                   0,
                   limit,
                   &block)

        control = find_paged_results_control(@controls)
        break if control.nil?

        _estimated_result_set_size, cookie = control.decode
        break if cookie.empty?
      end
    end
  end
end
