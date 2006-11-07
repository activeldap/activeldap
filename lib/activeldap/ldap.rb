# Extensions to Rubu/LDAP to make ActiveLDAP behave better
#
# Copyright 2006 Will Drewry <will@alum.bu.edu>
# Some portions Copyright 2006 Google Inc

require 'ldap'

module LDAP
  class PrettyError < LDAP::Error
  end

  ERRORS = [
    "LDAP_SUCCESS",
    "LDAP_OPERATIONS_ERROR",
    "LDAP_PROTOCOL_ERROR",
    "LDAP_TIMELIMIT_EXCEEDED",
    "LDAP_SIZELIMIT_EXCEEDED",
    "LDAP_COMPARE_FALSE",
    "LDAP_COMPARE_TRUE",
    "LDAP_STRONG_AUTH_NOT_SUPPORTED",
    "LDAP_AUTH_METHOD_NOT_SUPPORTED",
    "LDAP_STRONG_AUTH_REQUIRED",
    "LDAP_REFERRAL",
    "LDAP_ADMINLIMIT_EXCEEDED",
    "LDAP_UNAVAILABLE_CRITICAL_EXTENSION",
    "LDAP_CONFIDENTIALITY_REQUIRED",
    "LDAP_SASL_BIND_IN_PROGRESS",
    "LDAP_PARTIAL_RESULTS",
    "LDAP_NO_SUCH_ATTRIBUTE",
    "LDAP_UNDEFINED_TYPE",
    "LDAP_INAPPROPRIATE_MATCHING",
    "LDAP_CONSTRAINT_VIOLATION",
    "LDAP_TYPE_OR_VALUE_EXISTS",
    "LDAP_INVALID_SYNTAX",
    "LDAP_NO_SUCH_OBJECT",
    "LDAP_ALIAS_PROBLEM",
    "LDAP_INVALID_DN_SYNTAX",
    "LDAP_IS_LEAF",
    "LDAP_ALIAS_DEREF_PROBLEM",
    "LDAP_INAPPROPRIATE_AUTH",
    "LDAP_INVALID_CREDENTIALS",
    "LDAP_INSUFFICIENT_ACCESS",
    "LDAP_BUSY",
    "LDAP_UNAVAILABLE",
    "LDAP_UNWILLING_TO_PERFORM",
    "LDAP_LOOP_DETECT",
    "LDAP_NAMING_VIOLATION",
    "LDAP_OBJECT_CLASS_VIOLATION",
    "LDAP_NOT_ALLOWED_ON_NONLEAF",
    "LDAP_NOT_ALLOWED_ON_RDN",
    "LDAP_ALREADY_EXISTS",
    "LDAP_NO_OBJECT_CLASS_MODS",
    "LDAP_RESULTS_TOO_LARGE",
    "LDAP_OTHER",
    "LDAP_SERVER_DOWN",
    "LDAP_LOCAL_ERROR",
    "LDAP_ENCODING_ERROR",
    "LDAP_DECODING_ERROR",
    "LDAP_TIMEOUT",
    "LDAP_AUTH_UNKNOWN",
    "LDAP_FILTER_ERROR",
    "LDAP_USER_CANCELLED",
    "LDAP_PARAM_ERROR",
    "LDAP_NO_MEMORY",
    "LDAP_CONNECT_ERROR"
  ]
  attr_reader :error_map
  # Calls err2exception() with 1...100 to
  # pregenerate all the constants for errors.
  # TODO: look at other support LDAP SDKs for weirdness
  def LDAP.generate_err2exceptions()
    hash = {}
    ERRORS.each do |err|
      begin
        val = LDAP.const_get(err)
        # Make name into a exception
        exc = err.gsub(/^LDAP_/, '') 
        exc = exc.split('_').collect {|w| w.capitalize }.join('')
        # Doesn't exist :-)
        LDAP.module_eval(<<-end_module_eval)
          class #{exc} < LDAP::PrettyError
          end
        end_module_eval
        hash[val] = exc
      rescue NameError
        # next!
      end
    end
    @@error_map = hash
  end

  # Creates useful exceptions from @@conn.err output
  # Returns [exception, message] based on err2string
  def LDAP.err2exception(errno=0)
    need_to_rebuild = true
    begin
     exc = LDAP.const_get(@@error_map[errno])
    rescue NameError
     if need_to_rebuild
       generate_err2exceptions()
       need_to_rebuild = false
       retry
     end
     exc = RuntimeError
    end
    return [exc, err2string(errno)]
  end


end

# Generate LDAP constants
LDAP::generate_err2exceptions()
