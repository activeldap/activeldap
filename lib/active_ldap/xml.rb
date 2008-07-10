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
          values = normalize_values(values).sort_by {|value, _| value}
          result << serialize_attribute_values(key, values)
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
          xml_attributes = {}
          options.each do |name, val|
            xml_attributes[name] = val || "true"
          end
          targets << [value, xml_attributes]
        end
        targets
      end

      def serialize_attribute_values(name, values)
        return "" if values.blank?

        result = ""
        if name == "dn" or @options[:type].to_s.downcase == "ldif"
          values.collect do |value, xml_attributes|
            xml = serialize_attribute_value(name, value, xml_attributes)
            result << "  #{xml}\n"
          end
        else
          plural_name = name.pluralize
          result << "  <#{plural_name} type=\"array\">\n"
          values.each do |value, xml_attributes|
            xml = serialize_attribute_value(name, value, xml_attributes)
            result << "    #{xml}\n"
          end
          result << "  </#{plural_name}>\n"
        end
        result
      end

      def serialize_attribute_value(name, value, xml_attributes)
        if xml_attributes.blank?
          xml_attributes = ""
        else
          xml_attributes = " " + xml_attributes.collect do |n, v|
            "#{ERB::Util.h(n)}=\"#{ERB::Util.h(v)}\""
          end.join(" ")
        end
        "<#{name}#{xml_attributes}>#{ERB::Util.h(value)}</#{name}>"
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
