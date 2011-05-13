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
          include(GetText::Translation)
          po_dir = File.join(File.dirname(__FILE__), "..", "..", "po")
          po_dir = File.expand_path(po_dir)
          GetText.add_text_domain('active-ldap', :path => po_dir, :type => :po)
          GetText.default_available_locales = ['en', 'jp']
          GetText.default_text_domain = "active-ldap"
        end
      end
    end
  end
end
