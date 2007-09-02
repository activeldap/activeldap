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

      class CountryString < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.11"] = self

        def validate(value)
          if /\A[a-z\d"()+,\-.\/:? ]{2,2}\z/i =~ value
            nil
          else
            _("%s should be just 2 printable characters") % value.inspect
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

      class DirectoryString < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.15"] = self

        def validate(value)
          value.unpack("U*")
          nil
        rescue ArgumentError
          _("%s has invalid UTF-8 character") % value.inspect
        end
      end

      class GeneralizedTime < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.24"] = self

        def validate(value)
          match_data = /\A
                         (\d{4,4})?
                         (\d{2,2})?
                         (\d{2,2})?
                         (\d{2,2})?
                         (\d{2,2})?
                         (\d{2,2}(?:[,.]\d+)?)?
                         ([+-]\d{4,4}|Z)?
                        \z/x.match(value)
          if match_data
            year, month, day, hour, minute, second, time_zone =
              match_data.to_a[1..-1]
            missing_components = []
            %w(year month day hour minute).each do |component|
              missing_components << component unless eval(component)
            end
            if missing_components.empty?
              nil
            else
              params = [value.inspect, missing_components.join(", ")]
              _("%s has missing components: %s") % params
            end
          else
            _("%s is invalid time format")
          end
        end
      end

      class Integer < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.27"] = self

        def validate(value)
          Integer(value)
          nil
        rescue ArgumentError
          _("%s is invalid integer format") % value.inspect
        end
      end

      class JPEG < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.28"] = self

        def validate(value)
          if value.unpack("n")[0] == 0xffd8
            nil
          else
            _("invalid JPEG format")
          end
        end
      end
    end
  end
end
