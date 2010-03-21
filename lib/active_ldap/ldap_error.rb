module ActiveLdap
  class LdapError < Error
    class << self
      def define(code, name, target)
        klass_name = name.downcase.camelize
        target.module_eval(<<-EOC, __FILE__, __LINE__ + 1)
          class #{klass_name} < #{self}
            CODE = #{code}
            def code
              CODE
            end
          end
EOC
        target.const_get(klass_name)
      end
    end

    ERRORS = {}
    {
      0x00 => "SUCCESS",
      0x01 => "OPERATIONS_ERROR",
      0x02 => "PROTOCOL_ERROR",
      0x03 => "TIME_LIMIT_EXCEEDED",
      0x04 => "SIZE_LIMIT_EXCEEDED",
      0x05 => "COMPARE_FALSE",
      0x06 => "COMPARE_TRUE",
      0x07 => "AUTH_METHOD_NOT_SUPPORTED",
      0x08 => "STRONG_AUTH_REQUIRED",
      0x09 => "PARTIAL_RESULTS", # LDAPv2+ (not LDAPv3)

      0x0a => "REFERRAL",
      0x0b => "ADMIN_LIMIT_EXCEEDED",
      0x0c => "UNAVAILABLE_CRITICAL_EXTENSION",
      0x0d => "CONFIDENTIALITY_REQUIRED",
      0x0e => "LDAP_SASL_BIND_IN_PROGRESS",

      0x10 => "NO_SUCH_ATTRIBUTE",
      0x11 => "UNDEFINED_TYPE",
      0x12 => "INAPPROPRIATE_MATCHING",
      0x13 => "CONSTRAINT_VIOLATION",
      0x14 => "TYPE_OR_VALUE_EXISTS",
      0x15 => "INVALID_SYNTAX",

      0x20 => "NO_SUCH_OBJECT",
      0x21 => "ALIAS_PROBLEM",
      0x22 => "INVALID_DN_SYNTAX",
      0x23 => "IS_LEAF",
      0x24 => "ALIAS_DEREF_PROBLEM",

      0x2F => "PROXY_AUTHZ_FAILURE",
      0x30 => "INAPPROPRIATE_AUTH",
      0x31 => "INVALID_CREDENTIALS",
      0x32 => "INSUFFICIENT_ACCESS",

      0x33 => "BUSY",
      0x34 => "UNAVAILABLE",
      0x35 => "UNWILLING_TO_PERFORM",
      0x36 => "LOOP_DETECT",

      0x40 => "NAMING_VIOLATION",
      0x41 => "OBJECT_CLASS_VIOLATION",
      0x42 => "NOT_ALLOWED_ON_NONLEAF",
      0x43 => "NOT_ALLOWED_ON_RDN",
      0x44 => "ALREADY_EXISTS",
      0x45 => "NO_OBJECT_CLASS_MODS",
      0x46 => "RESULTS_TOO_LARGE",
      0x47 => "AFFECTS_MULTIPLE_DSAS",

      0x50 => "OTHER",
    }.each do |code, name|
      ERRORS[code] = LdapError.define(code, name, self)
    end
  end
end
