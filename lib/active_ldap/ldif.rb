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

      ATTRIBUTE_TYPE_CHARS = /[a-zA-Z][a-zA-Z0-9\-]*/
      SAFE_CHAR = /[\x01-\x09\x0B-\x0C\x0E-\x7F]/
      SAFE_INIT_CHAR = /[\x01-\x09\x0B-\x0C\x0E-\x1F\x21-\x39\x3B\x3D-\x7F]/
      SAFE_STRING = /#{SAFE_INIT_CHAR}#{SAFE_CHAR}*/
      def parse
        return @ldif if @ldif

        @scanner = Scanner.new(@source)
        raise version_spec_is_missing unless @scanner.scan(/version:/)
        @scanner.scan(/\s*/)
        raise version_spec_is_missing unless @scanner.scan(/(\d+)/)

        version = Integer(@scanner[1])
        raise unsupported_version(version) if version != 1

        raise separator_is_missing unless @scanner.scan_separators

        entries = parse_entries

        @ldif = LDIF.new(version, entries)
      end

      private
      def read_base64_value
        value = @scanner.scan(/[a-zA-Z0-9\+\/=]+/)
        raise base64_encoded_value_is_missing if value.nil?

        Base64.decode64(value).chomp
      end

      def parse_dn(dn_string)
        DN.parse(dn_string).to_s
      rescue DistinguishedNameInvalid
        invalid_ldif(_("DN is invalid: %s: %s") % [dn_string, $!.reason])
      end

      def parse_attributes
        attributes = {}
        type, options, value = parse_attribute
        attributes[type] = [value]
        while @scanner.scan_separator
          break if @scanner.scan_separator or @scanner.eos?
          type, options, value = parse_attribute
          attributes[type] ||= []
          attributes[type] << value
        end
        attributes
      end

      def parse_attribute
        type = @scanner.scan(ATTRIBUTE_TYPE_CHARS)
        raise attribute_type_is_missing if type.nil?
        options = parse_options
        value = parse_attribute_value
        [type, options, value]
      end

      def parse_options
        options = []
        while @scanner.scan(/;/)
          option = @scanner.scan(ATTRIBUTE_TYPE_CHARS)
          raise option_is_missing if option.nil?
          options << option
        end
        options
      end

      def parse_attribute_value
        raise attribute_value_separator_is_missing if @scanner.scan(/:/).nil?
        if @scanner.scan(/:/)
          @scanner.scan(/\s*/)
          read_base64_value
        elsif @scanner.scan(/</)
          raise not_implemented
        else
          @scanner.scan(/\s*/)
          @scanner.scan(/#{SAFE_STRING}?/)
        end
      end

      def parse_entry
        raise dn_mark_is_missing unless @scanner.scan(/dn:/)
        if @scanner.scan(/:\s*/)
          dn = parse_dn(read_base64_value)
        else
          @scanner.scan(/\s*/)
          dn = @scanner.scan(/.+$/)
          raise dn_is_missing if dn.nil?
          dn = parse_dn(dn)
        end

        raise separator_is_missing unless @scanner.scan_separators

        attributes = parse_attributes

        Entry.new(dn, attributes)
      end

      def parse_entries
        entries = []
        entries << parse_entry
        until @scanner.eos?
          entries << parse_entry
        end
        entries
      end

      def invalid_ldif(reason)
        LdifInvalid.new(@source, reason, @scanner.line, @scanner.column)
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

    class Scanner
      SEPARATOR = /(?:\r\n|\n)/

      def initialize(source)
        @source = source
        @scanner = StringScanner.new(@source)
        @sub_scanner = next_segment || StringScanner.new("")
      end

      def scan(regexp)
        @sub_scanner = next_segment if @sub_scanner.eos?
        @sub_scanner.scan(regexp)
      end

      def scan_separator
        return @scanner.scan(SEPARATOR) if @sub_scanner.eos?

        scan(SEPARATOR)
      end

      def scan_separators
        return @scanner.scan(/#{SEPARATOR}+/) if @sub_scanner.eos?

        sub_result = scan(/#{SEPARATOR}+/)
        return nil if sub_result.nil?

        result = @scanner.scan(/#{SEPARATOR}+/)
        return sub_result if result.nil?

        sub_result + result
      end

      def [](*args)
        @sub_scanner[*args]
      end

      def eos?
        @scanner.eos?
      end

      def line
        _consumed_source = consumed_source
        return 1 if _consumed_source.empty?

        n = _consumed_source.to_a.size
        n += 1 if _consumed_source[-1, 1] == "\n"
        n
      end

      def column
        _consumed_source = consumed_source
        return 1 if _consumed_source.empty? or _consumed_source[-1, 1] == "\n"

        position - ((_consumed_source.rindex("\n") || -1) + 1)
      end

      def position
        @scanner.pos - (@sub_scanner.string.length - @sub_scanner.pos)
      end

      private
      def next_segment
        segment = @scanner.scan(/.+(?:#{SEPARATOR} .*)*#{SEPARATOR}?/)
        return @sub_scanner if segment.nil?
        StringScanner.new(segment.gsub(/\r?\n /, ''))
      end

      def consumed_source
        @source[0,  position]
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
