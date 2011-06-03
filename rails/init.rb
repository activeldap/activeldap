require_library_or_gem 'active_ldap'
ActiveLdap::Base.logger ||= Rails.logger 

required_version = ["1", "1", "0"]
if (ActiveLdap::VERSION.split(".") <=> required_version) < 0
  ActiveLdap::Base.class_eval do
    format = _("You need ActiveLdap %s or later")
    logger.error(format % required_version.join("."))
  end
end

ldap_configuration_file = File.join(Rails.root, 'config', 'ldap.yml')
if File.exist?(ldap_configuration_file)
  configurations = YAML.load(ERB.new(IO.read(ldap_configuration_file)).result)
  ActiveLdap::Base.configurations = configurations
  ActiveLdap::Base.setup_connection
else
  ActiveLdap::Base.class_eval do
    format = _("You should run 'script/generator scaffold_active_ldap' to make %s.")
    logger.error(format % ldap_configuration_file)
  end
end

class ::ActionView::Base
  include ActiveLdap::Helper
end

# Expose Ldap runtime to controller for logging.
require "active_ldap/railties/controller_runtime"
ActiveSupport.on_load(:action_controller) do
  include ActiveLdap::Railties::ControllerRuntime
end

