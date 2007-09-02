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

        def valid?(value)
          validate(value).nil?
        end
      end

      class BitString < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.6"] = self

        def validate(value)
          if /\A'/ !~ value
            return _("%s doesn't have the first \"'\"" % value.inspect)
          end

          if /'B\z/ !~ value
            return _("%s doesn't have the last \"'B\"" % value.inspect)
          end

          if /([^01])/ =~ value[1..-3]
            return _("%s has invalid character '%s'" % [value.inspect, $1])
          end

          nil
        end
      end

      class Boolean < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.7"] = self

        def validate(value)
          if %w(TRUE FALSE).include?(value)
            nil
          else
            _("%s should be TRUE or FALSE") % value.inspect
          end
        end
      end

      class DistinguishedName < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.12"] = self

        def validate(value)
          DN.parse(value)
          nil
        rescue DistinguishedNameInvalid
          $!.message
        end
      end
    end
  end
end
