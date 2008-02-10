require_library_or_gem 'active_ldap'
ActiveLdap::Base.logger ||= RAILS_DEFAULT_LOGGER

required_version = ["0", "9", "1"]
if (ActiveLdap::VERSION.split(".") <=> required_version) < 0
  ActiveLdap::Base.class_eval do
    format = _("You need ActiveLdap %s or later")
    logger.error(format % required_version.join("."))
  end
end

ldap_configuration_file = File.join(RAILS_ROOT, 'config', 'ldap.yml')
if File.exist?(ldap_configuration_file)
  configurations = YAML.load(ERB.new(IO.read(ldap_configuration_file)).result)
  ActiveLdap::Base.configurations = configurations
  ActiveLdap::Base.establish_connection
else
  ActiveLdap::Base.class_eval do
    format = _("You should run 'script/generator scaffold_active_ldap' to make %s.")
    logger.error(format % ldap_configuration_file)
  end
end

class ::ActionView::Base
  include ActiveLdap::Helper
end

module ::ActionController
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

  class Base
    include LdapBenchmarking
  end
end
