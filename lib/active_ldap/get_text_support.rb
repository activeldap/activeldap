module ActiveLdap
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
