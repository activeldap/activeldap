require 'erb'

require 'active_ldap/ldif'

module ActiveLdap
  class Xml
    class Serializer
      PRINTABLE_STRING = /[\x20-\x7e\w\s]*/um

      def initialize(dn, attributes, options={})
        @dn = dn
        @attributes = attributes
        @options = options
      end

      def to_s
        root = @options[:root]
        result = "<#{root}>\n"
        target_attributes.each do |key, values|
          values = normalize_values(values).sort_by {|value, attr| value}
          values.each do |value, attr|
            attr = " #{attr}" unless attr.blank?
            result << "  <#{key}#{attr}>#{ERB::Util.h(value)}</#{key}>\n"
          end
        end
        result << "</#{root}>\n"
        result
      end

      private
      def target_attributes
        except_dn = false
        attributes = @attributes.dup
        (@options[:except] || []).each do |name|
          if name == "dn"
            except_dn = true
          else
            attributes.delete(name)
          end
        end
        attributes = attributes.sort_by {|key, values| key}
        attributes.unshift(["dn", [@dn]]) unless except_dn
        attributes
      end

      def normalize_values(values)
        targets = []
        values.each do |value|
          targets.concat(normalize_value(value))
        end
        targets
      end

      def normalize_value(value, options=[])
        targets = []
        if value.is_a?(Hash)
          value.each do |real_option, real_value|
            targets.concat(normalize_value(real_value, options + [real_option]))
          end
        elsif value.is_a?(Array)
          value.each do |real_value|
            targets.concat(normalize_value(real_value, options))
          end
        else
          if /\A#{PRINTABLE_STRING}\z/u !~ value
            value = [value].pack("m").gsub(/\n/u, '')
            options += ["base64"]
          end
          xml_attributes = options.collect do |name, val|
            "#{ERB::Util.h(name)}=\"#{ERB::Util.h(val || 'true')}\""
          end.join(" ")
          targets << [value, xml_attributes]
        end
        targets
      end
    end

    def initialize(dn, attributes)
      @dn = dn
      @attributes = attributes
    end

    def to_s(options={})
      Serializer.new(@dn, @attributes, options).to_s
    end
  end

  XML = Xml
end
