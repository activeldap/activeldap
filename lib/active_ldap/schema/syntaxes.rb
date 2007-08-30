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
        SYNTAXES = {}
      end

      class DistinguishedName < Base
        SYNTAXES["1.3.6.1.4.1.1466.115.121.1.12"] = self

        def valid?(value)
          begin
            DN.parse(value)
            true
          rescue DistinguishedNameInvalid
            false
          end
        end
      end
    end
  end
end
