require "gettext"

module ActiveLdap
  class << self
    def get_text_supported?
      true
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
