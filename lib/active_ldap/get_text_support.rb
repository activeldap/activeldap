module ActiveLdap
  class << self
    if const_defined?(:GetTextFallback)
      def get_text_support?
        false
      end
    else
      def get_text_support?
        true
      end
    end
  end

  module GetTextSupport
    class << self
      def included(base)
        base.class_eval do
          include(GetText)
          bindtextdomain("active-ldap")
        end
      end
    end
  end
end
