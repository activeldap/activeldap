require 'strscan'

module ActiveLdap
  class DistinguishedName
    class Parser
      attr_reader :dn
      def initialize(source)
        @dn = nil
        @source = source
      end

      def parse
        return @dn if @dn

        rdns = []
        scanner = StringScanner.new(@source)

        scanner.scan(/\s*/)
        raise rdn_is_missing if scanner.scan(/\s*\+\s*/)
        raise name_component_is_missing if scanner.scan(/\s*,\s*/)

        rdn = {}
        until scanner.eos?
          type = scan_attribute_type(scanner)
          skip_attribute_type_and_value_separator(scanner)
          value = scan_attribute_value(scanner)
          rdn[type] = value
          if scanner.scan(/\s*\+\s*/)
            raise rdn_is_missing if scanner.eos?
          elsif scanner.scan(/\s*\,\s*/)
            rdns << rdn
            rdn = {}
            raise name_component_is_missing if scanner.eos?
          else
            scanner.scan(/\s*/)
            rdns << rdn if scanner.eos?
          end
        end

        @dn = DN.new(*rdns)
        @dn
      end

      private
      ATTRIBUTE_TYPE_RE = /\s*([a-zA-Z][a-zA-Z\d\-]*|\d+(?:\.\d+)*)\s*/
      def scan_attribute_type(scanner)
        raise attribute_type_is_missing unless scanner.scan(ATTRIBUTE_TYPE_RE)
        scanner[1]
      end

      def skip_attribute_type_and_value_separator(scanner)
        raise attribute_value_is_missing unless scanner.scan(/\s*=\s*/)
      end

      HEX_PAIR = "(?:[\\da-fA-F]{2})"
      STRING_CHARS_RE = /[^,=\+<>\#;\\\"]*/ #
      PAIR_RE = /\\([,=\+<>\#;]|\\|\"|(#{HEX_PAIR}))/ #
      HEX_STRING_RE = /\#(#{HEX_PAIR}+)/ #
      def scan_attribute_value(scanner)
        if scanner.scan(HEX_STRING_RE)
          value = scanner[1].scan(/../).collect do |hex_pair|
            hex_pair.hex
          end.pack("C*")
        elsif scanner.scan(/\"/)
          value = scan_quoted_attribute_value(scanner)
        else
          value = scan_not_quoted_attribute_value(scanner)
        end
        raise attribute_value_is_missing if value.blank?

        value
      end

      def scan_quoted_attribute_value(scanner)
        result = ""
        until scanner.scan(/\"/)
          if scanner.scan(/([^\\\"]*)/)
            result << scanner[1]
          end
          result << collect_pairs(scanner)

          raise found_unmatched_quotation if scanner.eos?
        end
        result
      end

      def scan_not_quoted_attribute_value(scanner)
        result = ""
        until scanner.eos?
          pairs = collect_pairs(scanner)
          strings = scanner.scan(STRING_CHARS_RE)
          break if strings.blank? and pairs.blank?
          result << pairs unless pairs.nil? or pairs.empty?
          unless strings.nil?
            if scanner.peek(1) == ","
              result << strings.rstrip
            else
              result << strings
            end
          end
        end
        result
      end

      def collect_pairs(scanner)
        result = ""
        while scanner.scan(PAIR_RE)
          if scanner[2]
            result << [scanner[2].hex].pack("C*")
          else
            result << scanner[1]
          end
        end
        result
      end

      def invalid_dn(reason)
        DistinguishedNameInvalid.new(@source, reason)
      end

      def name_component_is_missing
        invalid_dn("name component is missing")
      end

      def rdn_is_missing
        invalid_dn("relative distinguished name (RDN) is missing")
      end

      def attribute_type_is_missing
        invalid_dn("attribute type is missing")
      end

      def attribute_value_is_missing
        invalid_dn("attribute value is missing")
      end

      def found_unmatched_quotation
        invalid_dn("found unmatched quotation")
      end
    end

    class << self
      def parse(source)
        Parser.new(source).parse
      end
    end

    include Comparable

    attr_reader :rdns
    def initialize(*rdns)
      @rdns = rdns.collect do |rdn|
        rdn = {rdn[0] => rdn[1]} if rdn.is_a?(Array) and rdn.size == 2
        rdn
      end
    end

    def <<(rdn)
      @rdns << rdn
    end

    def unshift(rdn)
      @rdns.unshift(rdn)
    end

    def ==(other)
      other.is_a?(self.class) and
        normalize(@rdns) == normalize(other.rdns)
    end

    private
    def normalize(rdns)
      rdns.collect do |rdn|
        normalized_rdn = {}
        rdn.each do |key, value|
          normalized_rdn[key.upcase] = value
        end
        normalized_rdn
      end
    end
  end

  DN = DistinguishedName
end
