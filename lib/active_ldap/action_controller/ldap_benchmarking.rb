module ActiveLdap
  module ActionController
    module LdapBenchmarking
      def self.included(base)
        base.class_eval do
          alias_method_chain :render, :active_ldap_benchmark
          alias_method_chain :rendering_runtime, :active_ldap
        end
      end

      protected
      def render_with_active_ldap_benchmark(*args, &block)
        if logger
          @ldap_runtime_before_render = ActiveLdap::Base.reset_runtime
          result = render_without_active_ldap_benchmark(*args, &block)
          @ldap_runtime_after_render = ActiveLdap::Base.reset_runtime
          @rendering_runtime -= @ldap_runtime_after_render
          result
        else
          render_without_active_ldap_benchmark(*args, &block)
        end
      end

      private
      def rendering_runtime_with_active_ldap(runtime)
        result = rendering_runtime_without_active_ldap(runtime)
        ldap_runtime = ActiveLdap::Base.reset_runtime
        ldap_runtime += @ldap_runtime_before_render || 0
        ldap_runtime += @ldap_runtime_after_render || 0
        ldap_percentage = ldap_runtime * 100 / runtime
        result + (" | LDAP: %.5f (%d%%)" % [ldap_runtime, ldap_percentage])
      end
    end
  end
end

