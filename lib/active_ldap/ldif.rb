require "strscan"
require "uri"
require "open-uri"

module ActiveLdap
  class Ldif
    module Attributes
      module_function
      def encode(attributes)
        return "" if attributes.empty?

        result = ""
        normalize(attributes).sort_by {|name,| name}.each do |name, values|
          values.each do |options, value|
            result << Attribute.encode([name, *options].join(";"), value)
          end
        end
        result
      end

      def normalize(attributes)
        result = {}
        attributes.each do |name, values|
          result[name] = Attribute.normalize_value(values).sort
        end
        result
      end
    end

    module Attribute
      SIZE = 75

      module_function
      def binary_value?(value)
        if value.respond_to?(:encoding)
          return true if value.encoding == Encoding.find("ascii-8bit")
        end
        if /\A#{Parser::SAFE_STRING}\z/ =~ value
          false
        else
          true
        end
      end

      def encode(name, value)
        return "#{name}:\n" if value.blank?
        result = "#{name}:"

        if value[-1, 1] == ' ' or binary_value?(value)
          result << ":"
          value = [value].pack("m").gsub(/\n/, '')
        end
        result << " "

        first_line_value_size = SIZE - result.size
        if value.size > first_line_value_size
          first_line_value = value[0, first_line_value_size]
          rest_value = value[first_line_value_size..-1]
        else
          first_line_value = value
          rest_value = nil
        end

        result << "#{first_line_value}\n"
        return result if rest_value.nil?

        rest_value.scan(/.{1,#{SIZE - 1}}/).each do |line| # FIXME
          result << " #{line}\n"
        end
        result
      end

      def normalize_value(value, result=[])
        case value
        when Array
          value.each {|val| normalize_value(val, result)}
        when Hash
          value.each do |option, val|
            normalize_value(val).each do |options, v|
              result << [[option] + options, v]
            end
          end
          result
        else
          result << [[], value]
        end
        result
      end
    end

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
      FILL = / */
      def parse
        return @ldif if @ldif

        @scanner = Scanner.new(@source)
        raise version_spec_is_missing unless @scanner.scan(/version:/)
        @scanner.scan(FILL)

        version = @scanner.scan(/\d+/)
        raise version_number_is_missing if version.nil?

        version = Integer(version)
        raise unsupported_version(version) if version != 1

        raise separator_is_missing unless @scanner.scan_separators

        records = parse_records

        @ldif = LDIF.new(records)
      end

      private
      def read_base64_value
        value = @scanner.scan(/[a-zA-Z0-9\+\/=]+/)
        return nil if value.nil?
        encoding = value.encoding if value.respond_to?(:encoding)
        value = value.unpack("m")[0].chomp
        if value.respond_to?(:force_encoding)
          value.force_encoding(encoding)
          value.force_encoding("ascii-8bit") unless value.valid_encoding?
        end
        value
      end

      def read_external_file
        uri_string = @scanner.scan(URI::ABS_URI)
        raise uri_is_missing if uri_string.nil?
        uri = nil
        begin
          uri = URI.parse(uri_string)
        rescue URI::Error
          raise invalid_uri(uri_string, $!.message)
        end

        if uri.scheme == "file"
          File.open(uri.path, "rb") {|file| file.read}
        else
          uri.read
        end
      end

      def parse_dn(dn_string)
        DN.parse(dn_string).to_s
      rescue DistinguishedNameInvalid
        raise invalid_dn(dn_string, $!.reason)
      end

      def parse_attributes(least=0, &block)
        i = 0
        attributes = {}
        block ||= Proc.new {@scanner.check_separator}
        loop do
          i += 1
          if i >= least
            break if block.call or @scanner.eos?
          end
          type, options, value = parse_attribute
          if @scanner.scan_separator.nil? and !@scanner.eos?
            raise separator_is_missing
          end
          attributes[type] ||= []
          container = attributes[type]
          options.each do |option|
            parent = container.find do |val|
              val.is_a?(Hash) and val.has_key?(option)
            end
            if parent.nil?
              parent = {option => []}
              container << parent
            end
            container = parent[option]
          end
          container << value
        end
        raise attribute_spec_is_missing if attributes.size < least
        attributes
      end

      def parse_attribute_description
        type = @scanner.scan(ATTRIBUTE_TYPE_CHARS)
        raise attribute_type_is_missing if type.nil?
        options = parse_options
        [type, options]
      end

      def parse_attribute
        type, options = parse_attribute_description
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

      def parse_attribute_value(accept_external_file=true)
        raise attribute_value_separator_is_missing if @scanner.scan(/:/).nil?
        if @scanner.scan(/:/)
          @scanner.scan(FILL)
          read_base64_value
        elsif accept_external_file and @scanner.scan(/</)
          @scanner.scan(FILL)
          read_external_file
        else
          @scanner.scan(FILL)
          @scanner.scan(SAFE_STRING)
        end
      end

      def parse_control
        return nil if @scanner.scan(/control:/).nil?
        @scanner.scan(FILL)
        type = @scanner.scan(/\d+(?:\.\d+)*/)
        raise control_type_is_missing if type.nil?
        criticality = nil
        if @scanner.scan(/ +/)
          criticality = @scanner.scan(/true|false/)
          raise criticality_is_missing if criticality.nil?
        end
        value = parse_attribute_value if @scanner.check(/:/)
        raise separator_is_missing unless @scanner.scan_separator
        ChangeRecord::Control.new(type, criticality, value)
      end

      def parse_controls
        controls = []
        loop do
          control = parse_control
          break if control.nil?
          controls << control
        end
        controls
      end

      def parse_change_type
        return nil unless @scanner.scan(/changetype:/)
        @scanner.scan(FILL)
        type = @scanner.check(ATTRIBUTE_TYPE_CHARS)
        raise change_type_value_is_missing if type.nil?
        unless @scanner.scan(/add|delete|modrdn|moddn|modify/)
          raise unknown_change_type(type)
        end

        raise separator_is_missing unless @scanner.scan_separator
        type
      end

      def parse_modify_name_record(klass, dn, controls)
        raise new_rdn_mark_is_missing unless @scanner.scan(/newrdn\b/)
        new_rdn = parse_attribute_value(false)
        raise new_rdn_value_is_missing if new_rdn.nil?
        raise separator_is_missing unless @scanner.scan_separator

        unless @scanner.scan(/deleteoldrdn:/)
          raise delete_old_rdn_mark_is_missing
        end
        @scanner.scan(FILL)
        delete_old_rdn = @scanner.scan(/[01]/)
        raise delete_old_rdn_value_is_missing if delete_old_rdn.nil?
        raise separator_is_missing unless @scanner.scan_separator

        if @scanner.scan(/newsuperior\b/)
          @scanner.scan(FILL)
          new_superior = parse_attribute_value(false)
          raise new_superior_value_is_missing if new_superior.nil?
          new_superior = parse_dn(new_superior)
          raise separator_is_missing unless @scanner.scan_separator
        end
        klass.new(dn, controls, new_rdn, delete_old_rdn, new_superior)
      end

      def parse_modify_spec
        return nil unless @scanner.check(/(#{ATTRIBUTE_TYPE_CHARS}):/)
        type = @scanner[1]
        unless @scanner.scan(/(?:add|delete|replace):/)
          raise unknown_modify_type(type)
        end
        @scanner.scan(FILL)
        attribute, options = parse_attribute_description
        raise separator_is_missing unless @scanner.scan_separator
        attributes = parse_attributes {@scanner.check(/-/)}
        raise modify_spec_separator_is_missing unless @scanner.scan(/-/)
        raise separator_is_missing unless @scanner.scan_separator
        [type, attribute, options, attributes]
      end

      def parse_modify_record(dn, controls)
        operations = []
        loop do
          spec = parse_modify_spec
          break if spec.nil?
          type, attribute, options, attributes = spec
          case type
          when "add"
            klass = ModifyRecord::AddOperation
          when "delete"
            klass = ModifyRecord::DeleteOperation
          when "replace"
            klass = ModifyRecord::ReplaceOperation
          else
            unknown_modify_type(type)
          end
          operations << klass.new(attribute, options, attributes)
        end
        ModifyRecord.new(dn, controls, operations)
      end

      def parse_change_type_record(dn, controls, change_type)
        case change_type
        when "add"
          attributes = parse_attributes(1)
          AddRecord.new(dn, controls, attributes)
        when "delete"
          DeleteRecord.new(dn, controls)
        when "moddn"
          parse_modify_name_record(ModifyDNRecord, dn, controls)
        when "modrdn"
          parse_modify_name_record(ModifyRDNRecord, dn, controls)
        when "modify"
          parse_modify_record(dn, controls)
        else
          raise unknown_change_type(change_type)
        end
      end

      def parse_record
        raise dn_mark_is_missing unless @scanner.scan(/dn:/)
        if @scanner.scan(/:/)
          @scanner.scan(FILL)
          dn = read_base64_value
          raise dn_is_missing if dn.nil?
          dn = parse_dn(dn)
        else
          @scanner.scan(FILL)
          dn = @scanner.scan(/#{SAFE_STRING}$/)
          if dn.nil?
            partial_dn = @scanner.scan(SAFE_STRING)
            raise dn_has_invalid_character(@scanner.check(/./)) if partial_dn
            raise dn_is_missing
          end
          dn = parse_dn(dn)
        end

        raise separator_is_missing unless @scanner.scan_separator

        controls = parse_controls
        change_type = parse_change_type
        raise change_type_is_missing if change_type.nil? and !controls.empty?

        if change_type
          parse_change_type_record(dn, controls, change_type)
        else
          attributes = parse_attributes(1)
          ContentRecord.new(dn, attributes)
        end
      end

      def parse_records
        records = []
        loop do
          records << parse_record
          break if @scanner.eos?
          raise separator_is_missing if @scanner.scan_separator.nil?

          break if @scanner.eos?
          break if @scanner.scan_separators and @scanner.eos?
        end
        records
      end

      def invalid_ldif(reason)
        LdifInvalid.new(@source, reason, @scanner.line, @scanner.column)
      end

      def version_spec_is_missing
        invalid_ldif(_("version spec is missing"))
      end

      def version_number_is_missing
        invalid_ldif(_("version number is missing"))
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

      def invalid_dn(dn_string, reason)
        invalid_ldif(_("DN is invalid: %s: %s") % [dn_string, reason])
      end

      def dn_has_invalid_character(character)
        invalid_ldif(_("DN has an invalid character: %s") % character)
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

      def invalid_uri(uri_string, message)
        invalid_ldif(_("URI is invalid: %s: %s") % [uri_string, message])
      end

      def modify_spec_separator_is_missing
        invalid_ldif(_("'-' is missing"))
      end

      def unknown_change_type(change_type)
        invalid_ldif(_("unknown change type: %s") % change_type)
      end

      def change_type_is_missing
        invalid_ldif(_("change type is missing"))
      end

      def control_type_is_missing
        invalid_ldif(_("control type is missing"))
      end

      def criticality_is_missing
        invalid_ldif(_("criticality is missing"))
      end

      def change_type_value_is_missing
        invalid_ldif(_("change type value is missing"))
      end

      def attribute_spec_is_missing
        invalid_ldif(_("attribute spec is missing"))
      end

      def new_rdn_mark_is_missing
        invalid_ldif(_("'newrdn:' is missing"))
      end

      def new_rdn_value_is_missing
        invalid_ldif(_("new RDN value is missing"))
      end

      def delete_old_rdn_mark_is_missing
        invalid_ldif(_("'deleteoldrdn:' is missing"))
      end

      def delete_old_rdn_value_is_missing
        invalid_ldif(_("delete old RDN value is missing"))
      end

      def new_superior_value_is_missing
        invalid_ldif(_("new superior value is missing"))
      end

      def unknown_modify_type(type)
        invalid_ldif(_("unknown modify type: %s") % type)
      end
    end

    class Scanner
      SEPARATOR = /(?:\r\n|\n)/
      SEPARATORS = /(?:(?:^#.*)?#{SEPARATOR})+/

      def initialize(source)
        @source = source
        @scanner = StringScanner.new(@source)
        @sub_scanner = nil
        @sub_scanner = next_segment || StringScanner.new("")
      end

      def scan(regexp)
        @sub_scanner = next_segment if @sub_scanner.eos?
        @sub_scanner.scan(regexp)
      end

      def check(regexp)
        @sub_scanner = next_segment if @sub_scanner.eos?
        @sub_scanner.check(regexp)
      end

      def scan_separator
        return @scanner.scan(SEPARATOR) if @sub_scanner.eos?

        scan(SEPARATOR)
      end

      def check_separator
        return @scanner.check(SEPARATOR) if @sub_scanner.eos?

        check(SEPARATOR)
      end

      def scan_separators
        return @scanner.scan(SEPARATORS) if @sub_scanner.eos?

        sub_result = scan(SEPARATORS)
        return nil if sub_result.nil?
        return sub_result unless @sub_scanner.eos?

        result = @scanner.scan(SEPARATORS)
        return sub_result if result.nil?

        sub_result + result
      end

      def [](*args)
        @sub_scanner[*args]
      end

      def eos?
        @sub_scanner = next_segment if @sub_scanner.eos?
        @sub_scanner.eos? and @scanner.eos?
      end

      def line
        _consumed_source = consumed_source
        return 1 if _consumed_source.empty?

        n = _consumed_source.lines.count
        n += 1 if _consumed_source[-1, 1] == "\n"
        n
      end

      def column
        _consumed_source = consumed_source
        return 1 if _consumed_source.empty?

        position - (_consumed_source.rindex("\n") || -1)
      end

      def position
        @scanner.pos - (@sub_scanner.string.bytesize - @sub_scanner.pos)
      end

      private
      def next_segment
        loop do
          segment = @scanner.scan(/.+(?:#{SEPARATOR} .*)*#{SEPARATOR}?/)
          return @sub_scanner if segment.nil?
          next if segment[0, 1] == "#"
          return StringScanner.new(segment.gsub(/\r?\n /, ''))
        end
      end

      def consumed_source
        @source[0, position]
      end
    end

    class << self
      def parse(ldif)
        Parser.new(ldif).parse
      end
    end

    include Enumerable

    attr_reader :version, :records
    def initialize(records=[])
      @version = 1
      @records = records
    end

    def <<(record)
      @records << record
    end

    def each(&block)
      @records.each(&block)
    end

    def to_s
      result = "version: #{@version}\n"
      result << @records.collect do |record|
        record.to_s
      end.join("\n")
      result
    end

    def ==(other)
      other.is_a?(self.class) and
        @version == other.version and @records == other.records
    end

    class Record
      include GetTextSupport

      attr_reader :dn, :attributes
      def initialize(dn, attributes)
        @dn = dn
        @attributes = attributes
      end

      def to_hash
        attributes.merge({"dn" => dn})
      end

      def to_s
        result = to_s_prelude
        result << to_s_content
        result
      end

      def ==(other)
        other.is_a?(self.class) and
          @dn == other.dn and
          Attributes.normalize(@attributes) ==
          Attributes.normalize(other.attributes)
      end

      private
      def to_s_prelude
        Attribute.encode("dn", dn)
      end

      def to_s_content
        Attributes.encode(@attributes)
      end
    end

    class ContentRecord < Record
    end

    class ChangeRecord < Record
      attr_reader :controls, :change_type
      def initialize(dn, attributes, controls, change_type)
        super(dn, attributes)
        @controls = controls
        @change_type = change_type
      end

      def add?
        @change_type == "add"
      end

      def delete?
        @change_type == "delete"
      end

      def modify?
        @change_type == "modify"
      end

      def modify_dn?
        @change_type == "moddn"
      end

      def modify_rdn?
        @change_type == "modrdn"
      end

      def ==(other)
        super(other) and
          @controls = other.controls and
          @change_type == other.change_type
      end

      private
      def to_s_prelude
        result = super
        @controls.each do |control|
          result << control.to_s
        end
        result
      end

      def to_s_content
        result = "changetype: #{@change_type}\n"
        result << super
        result
      end

      class Control
        attr_reader :type, :value
        def initialize(type, criticality, value)
          @type = type
          @criticality = normalize_criticality(criticality)
          @value = value
        end

        def criticality?
          @criticality
        end

        def to_a
          [@type, @criticality, @value]
        end

        def to_hash
          {
            :type => @type,
            :criticality => @criticality,
            :value => @value,
          }
        end

        def to_s
          result = "control: #{@type}"
          result << " #{@criticality}" unless @criticality.nil?
          result << @value if @value
          result << "\n"
          result
        end

        def ==(other)
          other.is_a?(self.class) and
            @type == other.type and
            @criticality = other.criticality and
            @value == other.value
        end

        private
        def normalize_criticality(criticality)
          case criticality
          when "true", true
            true
          when "false", false
            false
          when nil
            nil
          else
            raise ArgumentError,
                  _("invalid criticality value: %s") % criticality.inspect
          end
        end
      end
    end

    class AddRecord < ChangeRecord
      def initialize(dn, controls=[], attributes={})
        super(dn, attributes, controls, "add")
      end
    end

    class DeleteRecord < ChangeRecord
      def initialize(dn, controls=[])
        super(dn, {}, controls, "delete")
      end
    end

    class ModifyNameRecord < ChangeRecord
      attr_reader :new_rdn, :new_superior
      def initialize(dn, controls, change_type,
                     new_rdn, delete_old_rdn, new_superior)
        super(dn, {}, controls, change_type)
        @new_rdn = new_rdn
        @delete_old_rdn = normalize_delete_old_rdn(delete_old_rdn)
        @new_superior = new_superior
      end

      def delete_old_rdn?
        @delete_old_rdn
      end

      private
      def normalize_delete_old_rdn(delete_old_rdn)
        case delete_old_rdn
        when "1", true
          true
        when "0", false
          false
        when nil
          nil
        else
          raise ArgumentError,
                _("invalid deleteoldrdn value: %s") % delete_old_rdn.inspect
        end
      end

      def to_s_content
        result = super
        result << "newrdn: #{@new_rdn}\n"
        result << "deleteoldrdn: #{@delete_old_rdn ? 1 : 0}\n"
        result << Attribute.encode("newsuperior", @new_superior) if @new_superior
        result
      end
    end

    class ModifyDNRecord < ModifyNameRecord
      def initialize(dn, controls, new_rdn, delete_old_rdn, new_superior=nil)
        super(dn, controls, "moddn", new_rdn, delete_old_rdn, new_superior)
      end
    end

    class ModifyRDNRecord < ModifyNameRecord
      def initialize(dn, controls, new_rdn, delete_old_rdn, new_superior=nil)
        super(dn, controls, "modrdn", new_rdn, delete_old_rdn, new_superior)
      end
    end

    class ModifyRecord < ChangeRecord
      include Enumerable

      attr_reader :operations
      def initialize(dn, controls=[], operations=[])
        super(dn, {}, controls, "modify")
        @operations = operations
      end

      def each(&block)
        @operations.each(&block)
      end

      def <<(operation)
        @operations << operation
      end

      def add_operation(type, attribute, options, attributes)
        klass = self.class.const_get("#{type.to_s.capitalize}Operation")
        self << klass.new(attribute, options, attributes)
      end

      def ==(other)
        super(other) and @operations == other.operations
      end

      private
      def to_s_content
        result = super
        return result if @operations.empty?
        @operations.collect do |operation|
          result << "#{operation}-\n"
        end
        result
      end

      class Operation
        attr_reader :type, :attribute, :options, :attributes
        def initialize(type, attribute, options, attributes)
          @type = type
          @attribute = attribute
          @options = options
          @attributes = attributes
        end

        def full_attribute_name
          [@attribute, *@options].join(";")
        end

        def add?
          @type == "add"
        end

        def delete?
          @type == "delete"
        end

        def replace?
          @type == "replace"
        end

        def to_s
          Attribute.encode(@type, full_attribute_name) +
            Attributes.encode(@attributes)
        end

        def ==(other)
          other.is_a?(self.class) and
            @type == other.type and
            full_attribute_name == other.full_attribute_name and
            Attributes.normalize(@attributes) ==
            Attributes.normalize(other.attributes)
        end
      end

      class AddOperation < Operation
        def initialize(attribute, options, attributes)
          super("add", attribute, options, attributes)
        end
      end

      class DeleteOperation < Operation
        def initialize(attribute, options, attributes)
          super("delete", attribute, options, attributes)
        end
      end

      class ReplaceOperation < Operation
        def initialize(attribute, options, attributes)
          super("replace", attribute, options, attributes)
        end
      end
    end
  end

  LDIF = Ldif
end
