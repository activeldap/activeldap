# Experimental work-in-progress LDIF implementation.
# Don't care this file for now.

require 'strscan'
require 'base64'

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
        if scanner.scan(/:\s*/)
          dn = parse_dn(read_base64_value(scanner))
        else
          scanner.scan(/\s*/)
          dn = scanner.scan(/.+$/)
          raise dn_is_missing if dn.nil?
          dn = parse_dn(dn)
        end

        raise separator_is_missing unless scanner.scan(SEPARATOR)

        @ldif = LDIF.new(version, [Entry.new(dn)])
      end

      private
      def read_base64_value(scanner)
        value = scanner.scan(/(?:[a-zA-Z0-9\+\/=]|#{SEPARATOR} )+/)
        raise base64_encoded_value_is_missing if value.nil?

        Base64.decode64(value.gsub(/#{SEPARATOR} /, '')).chomp
      end

      def parse_dn(dn_string)
        DN.parse(dn_string).to_s
      rescue DistinguishedNameInvalid
        invalid_ldif(_("DN is invalid: %s: %s") % [dn_string, $!.reason])
      end

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

      def dn_is_missing
        invalid_ldif(_("DN is missing"))
      end

      def base64_encoded_value_is_missing
        invalid_ldif(_("Base64 encoded value is missing"))
      end
    end

    class << self
      def parse(ldif)
        Parser.new(ldif).parse
      end
    end

    attr_reader :version, :entries
    def initialize(version, entries)
      @version = version
      @entries = entries
    end

    class Entry
      attr_reader :dn
      def initialize(dn)
        @dn = dn
      end
    end
  end

  LDIF = Ldif
end
