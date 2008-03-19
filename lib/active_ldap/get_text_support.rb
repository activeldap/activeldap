module ActiveLdap
  class << self
    def get_text_supported?
      not const_defined?(:GetTextFallback)
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
