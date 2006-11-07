module ActiveLDAP
  module Adaptor
    class Base
      def initialize(config={})
        @connection = nil
        @config = config.dup
        @logger = @config.delete(:logger)
        @reconnect_attempts = 0
        %w(host port method timeout retry_on_timeout
           retry_limit retry_wait bind_format user password
           password_block try_sasl allow_anonymous
           store_password).each do |name|
          instance_variable_set("@#{name}", config[name.to_sym])
        end
      end

      private
      def with_timeout(try_reconnect=true, &block)
        begin
          Timeout.alarm(@timeout, &block)
        rescue Timeout::Error => e
          @logger.error {'Requested action timed out.'}
          retry if try_reconnect and @retry_on_timeout and reconnect
          @logger.error {e.message}
          raise TimeoutError, e.message
        end
      end

      # make_subtypes
      #
      # Makes the Hashized value from the full attributename
      # e.g. userCertificate;binary => "some_bin"
      #      becomes userCertificate => {"binary" => "some_bin"}
      def make_subtypes(attr, value)
        @logger.debug {"stub: called make_subtypes(#{attr.inspect}, " +
                       "#{value.inspect})"}
        return [attr, value] unless attr.match(/;/)

        ret_attr, *subtypes = attr.split(/;/)
        return [ret_attr, [make_subtypes_helper(subtypes, value)]]
      end

      # make_subtypes_helper
      #
      # This is a recursive function for building
      # nested hashed from multi-subtyped values
      def make_subtypes_helper(subtypes, value)
        @logger.debug {"stub: called make_subtypes_helper" +
                       "(#{subtypes.inspect}, #{value.inspect})"}
        return value if subtypes.size == 0
        return {subtypes[0] => make_subtypes_helper(subtypes[1..-1], value)}
      end

      def unnormalize_attributes(attributes)
        result = {}
        attributes.each do |name, values|
          unnormalize_attribute(name, values, result)
        end
        result
      end

      def unnormalize_attribute(name, values, result={})
        values.each do |value|
          if value.is_a?(Hash)
            suffix, real_value = extract_subtypes(value)
            new_name = name + suffix
            result[new_name] ||= []
            result[new_name].concat(real_value)
          else
            result[name] ||= []
            result[name] << value.dup
          end
        end
        result
      end

      # extract_subtypes
      #
      # Extracts all of the subtypes from a given set of nested hashes
      # and returns the attribute suffix and the final true value
      def extract_subtypes(value)
        @logger.debug {"stub: called extract_subtypes(#{value.inspect})"}
        subtype = ''
        ret_val = value
        if value.class == Hash
          subtype = ';' + value.keys[0]
          ret_val = value[value.keys[0]]
          subsubtype = ''
          if ret_val.class == Hash
            subsubtype, ret_val = extract_subtypes(ret_val)
          end
          subtype += subsubtype
        end
        ret_val = [ret_val] unless ret_val.class == Array
        return subtype, ret_val
      end
    end
  end
end
