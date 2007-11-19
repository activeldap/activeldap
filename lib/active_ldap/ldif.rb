# Experimental work-in-progress LDIF implementation.
# Don't care this file for now.

require 'strscan'

module ActiveLdap
  class Ldif
    include GetTextSupport

    class Parser
      include GetTextSupport

      attr_reader :ldif
      def initialize(source)
        @ldif = nil
        source = source.to_s if source.is_a?(LDIF)
        @source = source
      end

      SEPARATOR = /(?:\r\n|\n)/
      def parse
        return @ldif if @ldif

        scanner = StringScanner.new(@source)
        raise version_spec_is_missing unless scanner.scan(/version:\s*(\d+)/)

        version = Integer(scanner[1])
        raise unsupported_version(version) if version != 1

        raise separator_is_missing unless scanner.scan(/#{SEPARATOR}+/)

        raise dn_mark_is_missing unless scanner.scan(/dn:/)

        @ldif = LDIF.new(version)
      end

      private
      def invalid_ldif(reason)
        LdifInvalid.new(@source, reason)
      end

      def version_spec_is_missing
        invalid_ldif(_("version spec is missing"))
      end

      def unsupported_version(version)
        invalid_ldif(_("unsupported version: %d") % version)
      end

      def separator_is_missing
        invalid_ldif(_("separator is missing"))
      end

      def dn_mark_is_missing
        invalid_ldif(_("'dn:' is missing"))
      end
    end

    class << self
      def parse(ldif)
        Parser.new(ldif).parse
      end
    end

    attr_reader :version
    def initialize(version)
      @version = version
    end
  end

  LDIF = Ldif
end
