require 'ldap'
require 'ldap/ldif'
require 'ldap/schema'

module LDAP
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
    def failed?
      not err.zero?
    end

    def error_message
      if failed?
        LDAP.err2string(err)
      else
        nil
      end
    end

    def assert_error_code
      return unless failed?
      klass = ActiveLdap::LdapError::ERRORS[err]
      klass ||= IMPLEMENT_SPECIFIC_ERRORS[err]
      klass ||= ActiveLdap::LdapError
      raise klass, LDAP.err2string(err)
    end
  end
end
