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
      ATTRIBUTE_TYPE_CHARS = /[a-zA-Z][a-zA-Z0-9\-]*/
      SAFE_CHAR = /[\x01-\x09\x0B-\x0C\x0E-\x7F]/
      SAFE_INIT_CHAR = /[\x01-\x09\x0B-\x0C\x0E-\x1F\x21-\x39\x3B\x3D-\x7F]/
      SAFE_STRING = /#{SAFE_INIT_CHAR}#{SAFE_CHAR}*/
      def parse
        return @ldif if @ldif

        scanner = StringScanner.new(@source)
        raise version_spec_is_missing unless scanner.scan(/version:\s*(\d+)/)

        version = Integer(scanner[1])
        raise unsupported_version(version) if version != 1

        raise separator_is_missing unless scanner.scan(/#{SEPARATOR}+/)

        entries = parse_entries(scanner)

        @ldif = LDIF.new(version, entries)
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

      def parse_attributes(scanner)
        attributes = {}
        type, options, value = parse_attribute(scanner)
        attributes[type] = [value]
        while scanner.scan(SEPARATOR)
          break if scanner.scan(/#{SEPARATOR}+/) or scanner.eos?
          type, options, value = parse_attribute(scanner)
          attributes[type] ||= []
          attributes[type] << value
        end
        attributes
      end

      def parse_attribute(scanner)
        type = scanner.scan(ATTRIBUTE_TYPE_CHARS)
        raise attribute_type_is_missing if type.nil?
        options = parse_options(scanner)
        value = parse_attribute_value(scanner)
        [type, options, value]
      end

      def parse_options(scanner)
        options = []
        while scanner.scan(/;/)
          option = scanner.scan(ATTRIBUTE_TYPE_CHARS)
          raise option_is_missing if option.nil?
          options << option
        end
        options
      end

      def parse_attribute_value(scanner)
        raise attribute_value_separator_is_missing if scanner.scan(/:/).nil?
        if scanner.scan(/:/)
          scanner.scan(/\s*/)
          read_base64_value(scanner)
        elsif scanner.scan(/</)
          raise not_implemented
        else
          scanner.scan(/\s*/)
          scanner.scan(/#{SAFE_STRING}?/)
        end
      end

      def parse_entry(scanner)
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

        attributes = parse_attributes(scanner)

        Entry.new(dn, attributes)
      end

      def parse_entries(scanner)
        entries = []
        entries << parse_entry(scanner)
        until scanner.eos?
          entries << parse_entry(scanner)
        end
        entries
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

      def attribute_type_is_missing
        invalid_ldif(_("attribute type is missing"))
      end

      def option_is_missing
        invalid_ldif(_("option is missing"))
      end

      def attribute_value_separator_is_missing
        invalid_ldif(_("':' is missing"))
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
      attr_reader :dn, :attributes
      def initialize(dn, attributes)
        @dn = dn
        @attributes = attributes
      end

      def to_hash
        attributes.merge({"dn" => dn})
      end
    end
  end

  LDIF = Ldif
end
