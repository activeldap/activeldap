require 'erb'
require 'builder'

require 'active_ldap/ldif'

module ActiveLdap
  class Xml
    class Serializer
      PRINTABLE_STRING = /[\x20-\x7e\w\s]*/

      def initialize(dn, attributes, schema, options={})
        @dn = dn
        @attributes = attributes
        @schema = schema
        @options = options
      end

      def to_s
        root = @options[:root]
        indent = @options[:indent] || 2
        xml = @options[:builder] || Builder::XmlMarkup.new(:indent => indent)
        xml.tag!(root) do
          target_attributes.each do |key, values|
            values = normalize_values(values).sort_by {|value, _| value}
            if @schema.attribute(key).single_value?
              serialize_attribute_value(xml, key, *values[0])
            else
              serialize_attribute_values(xml, key, values)
            end
          end
        end
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
          if /\A#{PRINTABLE_STRING}\z/ !~ value
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

      def serialize_attribute_values(xml, name, values)
        return if values.blank?

        if name == "dn" or @options[:type].to_s.downcase == "ldif"
          values.each do |value, xml_attributes|
            serialize_attribute_value(xml, name, value, xml_attributes)
          end
        else
          plural_name = name.pluralize
          attributes = @options[:skip_types] ? {} : {"type" => "array"}
          xml.tag!(plural_name, attributes) do
            values.each do |value, xml_attributes|
              serialize_attribute_value(xml, name, value, xml_attributes)
            end
          end
        end
      end

      def serialize_attribute_value(xml, name, value, xml_attributes)
        xml.tag!(name, value, xml_attributes)
      end
    end

    def initialize(dn, attributes, schema)
      @dn = dn
      @attributes = attributes
      @schema = schema
    end

    def to_s(options={})
      Serializer.new(@dn, @attributes, @schema, options).to_s
    end
  end

  XML = Xml
end
