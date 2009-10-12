module ActiveLdap
  module Attributes
    def self.included(base)
      base.class_eval do
        extend(ClassMethods)
        extend(Normalizable)
        include(Normalizable)
      end
    end

    module ClassMethods
      def attr_protected(*attributes)
        targets = attributes.collect {|attr| attr.to_s} - protected_attributes
        instance_variable_set("@attr_protected", targets)
      end

      def protected_attributes
        ancestors[0..(ancestors.index(Base))].inject([]) do |result, ancestor|
          result + ancestor.instance_eval {@attr_protected ||= []}
        end
      end

      def blank_value?(value)
        case value
        when Hash
          value.values.all? {|val| blank_value?(val)}
        when Array
          value.all? {|val| blank_value?(val)}
        when String
          /\A\s*\z/ =~ value
        when nil
          true
        else
          value.blank?
        end
      end

      def remove_blank_value(value)
        case value
        when Hash
          result = {}
          value.each do |k, v|
            v = remove_blank_value(v)
            next if v.nil?
            result[k] = v
          end
          result = nil if result.blank?
          result
        when Array
          result = []
          value.each do |v|
            v = remove_blank_value(v)
            next if v.nil?
            result << v
          end
          result = nil if result.blank?
          result
        when String
          if /\A\s*\z/ =~ value
            nil
          else
            value
          end
        else
          value
        end
      end
    end

    module Normalizable
      def normalize_attribute_name(name)
        name.to_s.downcase
      end

      # Enforce typing:
      # Hashes are for subtypes
      # Arrays are for multiple entries
      def normalize_attribute(name, value)
        if name.nil?
          raise RuntimeError, _('The first argument, name, must not be nil. ' \
                                'Please report this as a bug!')
        end

        name = normalize_attribute_name(name)
        [name, schema.attribute(name).normalize_value(value)]
      end

      def unnormalize_attributes(attributes)
        result = {}
        attributes.each do |name, values|
          unnormalize_attribute(name, values, result)
        end
        result
      end

      def unnormalize_attribute(name, values, result={})
        if values.empty?
          result[name] = []
        else
          values.each do |value|
            if value.is_a?(Hash)
              suffix, real_value = unnormalize_attribute_options(value)
              new_name = name + suffix
              result[new_name] ||= []
              result[new_name].concat(real_value)
            else
              result[name] ||= []
              if value.is_a?(DN)
                result[name] << value.to_s
              else
                result[name] << value.dup
              end
            end
          end
        end
        result
      end

      # normalize_attribute_options
      #
      # Makes the Hashized value from the full attribute name
      # e.g. userCertificate;binary => "some_bin"
      #      becomes userCertificate => {"binary" => "some_bin"}
      def normalize_attribute_options(attr, value)
        return [attr, value] unless attr.match(/;/)

        ret_attr, *options = attr.split(/;/)
        [ret_attr,
         [options.reverse.inject(value) {|result, option| {option => result}}]]
      end

      # unnormalize_attribute_options
      #
      # Unnormalizes all of the subtypes from a given set of nested hashes
      # and returns the attribute suffix and the final true value
      def unnormalize_attribute_options(value)
        options = ''
        ret_val = value
        if value.class == Hash
          options = ';' + value.keys[0]
          ret_val = value[value.keys[0]]
          if ret_val.class == Hash
            sub_options, ret_val = unnormalize_attribute_options(ret_val)
            options += sub_options
          end
        end
        ret_val = [ret_val] unless ret_val.class == Array
        [options, ret_val]
      end
    end

    private
    def remove_attributes_protected_from_mass_assignment(targets)
      needless_attributes = {}
      (attributes_protected_by_default +
       (self.class.protected_attributes || [])).each do |name|
        needless_attributes[to_real_attribute_name(name)] = true
      end

      _dn_attribute = nil
      begin
        _dn_attribute = dn_attribute_with_fallback
      rescue DistinguishedNameInvalid
      end
      targets.collect do |key, value|
        key = _dn_attribute if ["id", "dn"].include?(key.to_s)
        [to_real_attribute_name(key) || key, value]
      end.reject do |key, value|
        needless_attributes[key]
      end
    end

    def attributes_protected_by_default
      begin
        _dn_attribute = dn_attribute_with_fallback
      rescue DistinguishedNameInvalid
      end
      [_dn_attribute, 'objectClass'].compact
    end

    def normalize_attribute_name(name)
      self.class.normalize_attribute_name(name)
    end
  end
end
