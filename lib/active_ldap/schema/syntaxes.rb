module ActiveLdap
  class Schema
    module Syntaxes
      class << self
        def [](id)
          syntax = Base::SYNTAXES[id]
          if syntax
            syntax.new
          else
            nil
          end
        end
      end

      class Base
        include GetTextSupport
        SYNTAXES = {}

        printable_character_source = "a-zA-Z\\d\"()+,\\-.\\/:? "
        PRINTABLE_CHARACTER = /[#{printable_character_source}]/ #
        UNPRINTABLE_CHARACTER = /[^#{printable_character_source}]/ #

        def binary?
          false
        end

        def type_cast(value)
          value
        end

        def valid?(value)
          validate(value).nil?
        end

        def validate(value)
          validate_normalized_value(normalize_value(value), value)
        end

        def normalize_value(value)
          value
        end
      end

      class BitString < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.6"] = self

        def type_cast(value)
          return nil if value.nil?
          if /\A'([01]*)'B\z/ =~ value.to_s
            $1
          else
            value
          end
        end

        def normalize_value(value)
          if value.is_a?(String) and /\A[01]*\z/ =~ value
            "'#{value}'B"
          else
            value
          end
        end

        private
        def validate_normalized_value(value, original_value)
          if /\A'/ !~ value
            return _("%s doesn't have the first \"'\"") % original_value.inspect
          end

          if /'B\z/ !~ value
            return _("%s doesn't have the last \"'B\"") % original_value.inspect
          end

          if /([^01])/ =~ value[1..-3]
            return _("%s has invalid character '%s'") % [value.inspect, $1]
          end

          nil
        end
      end

      class Boolean < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.7"] = self

        def type_cast(value)
          case value
          when "TRUE"
            true
          when "FALSE"
            false
          else
            value
          end
        end

        def normalize_value(value)
          case value
          when true, "1"
            "TRUE"
          when false, "0"
            "FALSE"
          else
            value
          end
        end

        private
        def validate_normalized_value(value, original_value)
          if %w(TRUE FALSE).include?(value)
            nil
          else
            _("%s should be TRUE or FALSE") % original_value.inspect
          end
        end
      end

      class CountryString < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.11"] = self

        private
        def validate_normalized_value(value, original_value)
          if /\A#{PRINTABLE_CHARACTER}{2,2}\z/i =~ value
            nil
          else
            format = _("%s should be just 2 printable characters")
            format % original_value.inspect
          end
        end
      end

      class DistinguishedName < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.12"] = self

        def type_cast(value)
          return nil if value.nil?
          DN.parse(value)
        rescue DistinguishedNameInvalid
          value
        end

        def normalize_value(value)
          if value.is_a?(DN)
            value.to_s
          else
            value
          end
        end

        private
        def validate_normalized_value(value, original_value)
          DN.parse(value)
          nil
        rescue DistinguishedNameInvalid
          $!.message
        end
      end

      class DirectoryString < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.15"] = self

        private
        def validate_normalized_value(value, original_value)
          value.unpack("U*")
          nil
        rescue ArgumentError
          _("%s has invalid UTF-8 character") % original_value.inspect
        end
      end

      class GeneralizedTime < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.24"] = self
        FORMAT = /\A
                  (\d{4,4})?
                  (\d{2,2})?
                  (\d{2,2})?
                  (\d{2,2})?
                  (\d{2,2})?
                  (\d{2,2})?
                  ([,.]\d+)?
                  ([+-]\d{4,4}|Z)?
                 \z/x

        def type_cast(value)
          return value if value.nil? or value.is_a?(Time)
          match_data = FORMAT.match(value)
          if match_data
            required_components = match_data.to_a[1, 5]
            return value if required_components.any?(&:nil?)
            year, month, day, hour, minute = required_components.collect(&:to_i)
            second = match_data[-3].to_i
            fraction = match_data[-2]
            fraction = fraction.to_f if fraction
            time_zone = match_data[-1]
            arguments = [
              value, year, month, day, hour, minute, second, fraction, time_zone,
              Time.now,
            ]
            if Time.method(:make_time).arity == 11
              arguments[2, 0] = nil
            end
            begin
              Time.send(:make_time, *arguments)
            rescue ArgumentError
              raise if year >= 1700
              out_of_range_messages = ["argument out of range",
                                       "time out of range"]
              raise unless out_of_range_messages.include?($!.message)
              Time.at(0)
            rescue RangeError
              raise if year >= 1700
              raise if $!.message != "bignum too big to convert into `long'"
              Time.at(0)
            end
          else
            value
          end
        end

        def normalize_value(value)
          if value.is_a?(Time)
            normalized_value = value.strftime("%Y%m%d%H%M%S")
            if value.gmt?
              normalized_value + "Z"
            else
              # for timezones with non-zero minutes, such as IST which is +0530,
              # divmod(3600) will give wrong value of 1800

              offset = value.gmtoff / 60 # in minutes
              normalized_value + ("%+03d%02d" % offset.divmod(60))
            end
          else
            value
          end
        end

        private
        def validate_normalized_value(value, original_value)
          match_data = FORMAT.match(value)
          if match_data
            date_data = match_data.to_a[1..-1]
            missing_components = []
            required_components = %w(year month day hour minute)
            required_components.each_with_index do |component, i|
              missing_components << component unless date_data[i]
            end
            if missing_components.empty?
              nil
            else
              params = [original_value.inspect, missing_components.join(", ")]
              _("%s has missing components: %s") % params
            end
          else
            _("%s is invalid time format") % original_value.inspect
          end
        end
      end

      class Integer < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.27"] = self

        def type_cast(value)
          return value if value.nil?
          begin
            Integer(value)
          rescue ArgumentError
            value
          end
        end

        def normalize_value(value)
          if value.is_a?(::Integer)
            value.to_s
          else
            value
          end
        end

        private
        def validate_normalized_value(value, original_value)
          Integer(value)
          nil
        rescue ArgumentError
          _("%s is invalid integer format") % original_value.inspect
        end
      end

      class JPEG < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.28"] = self

        def binary?
          true
        end

        private
        def validate_normalized_value(value, original_value)
          if value.unpack("n")[0] == 0xffd8
            nil
          else
            _("invalid JPEG format")
          end
        end
      end

      class NameAndOptionalUID < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.34"] = self

        private
        def validate_normalized_value(value, original_value)
          separator_index = value.rindex("#")
          if separator_index
            dn = value[0, separator_index]
            bit_string = value[(separator_index + 1)..-1]
            bit_string_reason = BitString.new.validate(bit_string)
            dn_reason = DistinguishedName.new.validate(dn)
            if bit_string_reason
              if dn_reason
                value_reason = DistinguishedName.new.validate(value)
                return nil unless value_reason
                dn_reason
              else
                bit_string_reason
              end
            else
              dn_reason
            end
          else
            DistinguishedName.new.validate(value)
          end
        end
      end

      class NumericString < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.36"] = self

        private
        def validate_normalized_value(value, original_value)
          if /\A\d+\z/ =~ value
            nil
          else
            _("%s is invalid numeric format") % original_value.inspect
          end
        end
      end

      class OID < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.38"] = self

        private
        def validate_normalized_value(value, original_value)
          DN.parse("#{value}=dummy")
          nil
        rescue DistinguishedNameInvalid
          reason = $!.reason
          if reason
            _("%s is invalid OID format: %s") % [original_value.inspect, reason]
          else
            _("%s is invalid OID format") % original_value.inspect
          end
        end
      end

      class OtherMailbox < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.39"] = self

        private
        def validate_normalized_value(value, original_value)
          type, mailbox = value.split('$', 2)

          if type.empty?
            return _("%s has no mailbox type") % original_value.inspect
          end

          if /(#{UNPRINTABLE_CHARACTER})/i =~ type
            format = _("%s has unprintable character in mailbox type: '%s'")
            return format % [original_value.inspect, $1]
          end

          if mailbox.blank?
            return _("%s has no mailbox") % original_value.inspect
          end

          nil
        end
      end

      class OctetString < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.40"] = self

        def binary?
          true
        end

        private
        def validate_normalized_value(value, original_value)
          nil
        end
      end

      class PostalAddress < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.41"] = self

        private
        def validate_normalized_value(value, original_value)
          if value.blank?
            return _("empty string")
          end

          begin
            value.unpack("U*")
          rescue ArgumentError
            return _("%s has invalid UTF-8 character") % original_value.inspect
          end

          nil
        end
      end

      class PrintableString < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.44"] = self

        private
        def validate_normalized_value(value, original_value)
          if value.blank?
            return _("empty string")
          end

          if /(#{UNPRINTABLE_CHARACTER})/i =~ value
            format = _("%s has unprintable character: '%s'")
            return format % [original_value.inspect, $1]
          end

          nil
        end
      end

      class TelephoneNumber < PrintableString
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.50"] = self

        private
        def validate_normalized_value(value, original_value)
          return nil if value.blank?
          super
        end
      end

      class ObjectSecurityDescriptor < OctetString
        # @see http://tools.ietf.org/html/draft-armijo-ldap-syntax-00
        #   Object-Security-Descriptor: 1.2.840.113556.1.4.907
        #
        #   Encoded as an Octet-String (OID 1.3.6.1.4.1.1466.115.121.1.40)
        #
        # @see http://msdn.microsoft.com/en-us/library/cc223229.aspx
        #   String(NT-Sec-Desc) 1.2.840.113556.1.4.907
        SYNTAXES["1.2.840.113556.1.4.907"] = self
      end

      class UnicodePwd < OctetString
        # @see http://msdn.microsoft.com/en-us/library/cc220961.aspx
        #   cn: Unicode-Pwd
        #   ldapDisplayName: unicodePwd
        #   attributeId: 1.2.840.113556.1.4.90
        #   attributeSyntax: 2.5.5.10
        #   omSyntax: 4
        #   isSingleValued: TRUE
        #   schemaIdGuid: bf9679e1-0de6-11d0-a285-00aa003049e2
        #   systemOnly: FALSE
        #   searchFlags: 0
        #   systemFlags: FLAG_SCHEMA_BASE_OBJECT
        #   schemaFlagsEx: FLAG_ATTR_IS_CRITICAL
        #
        # @see http://msdn.microsoft.com/en-us/library/cc223177.aspx
        #   String(Octet) 2.5.5.10
        SYNTAXES["1.2.840.113556.1.4.90"] = self
      end
    end
  end
end
