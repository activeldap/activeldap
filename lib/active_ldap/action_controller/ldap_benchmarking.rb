module ActiveLdap
  module ActionController
    module LdapBenchmarking
      def self.included(base)
        base.class_eval do
          alias_method_chain :render_with_benchmark, :active_ldap_benchmark
          if private_method_defined?(:view_runtime)
            alias_method_chain :view_runtime, :active_ldap
          else
            alias_method_chain :rendering_runtime, :active_ldap
          end
        end
      end

      protected
      def render_with_benchmark_with_active_ldap_benchmark(*args, &block)
        if logger
          ldap_runtime_before_render = ActiveLdap::Base.reset_runtime
        end
        result = render_with_benchmark_without_active_ldap_benchmark(*args,
                                                                     &block)
        if logger
          @ldap_runtime_before_render = ldap_runtime_before_render
          @ldap_runtime_after_render = ActiveLdap::Base.reset_runtime
          if defined?(@rendering_runtime)
            @rendering_runtime -= @ldap_runtime_after_render
          else
            @view_runtime -= @ldap_runtime_after_render
          end
        end
        result
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

      def view_runtime_with_active_ldap
        result = view_runtime_without_active_ldap
        ldap_runtime = ActiveLdap::Base.reset_runtime
        @ldap_runtime_before_render ||= 0
        @ldap_runtime_after_render ||= 0
        ldap_runtime += @ldap_runtime_before_render
        ldap_runtime += @ldap_runtime_after_render
        result + (", LDAP: %.0f" % (ldap_runtime * 1000))
      end
    end
  end
end

