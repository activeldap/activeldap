require_library_or_gem 'active_ldap'
ActiveLdap::Base.logger ||= RAILS_DEFAULT_LOGGER

required_version = ["0", "8", "3"]
if (ActiveLdap::VERSION.split(".") <=> required_version) < 0
  ActiveLdap::Base.class_eval do
    format = _("You need ActiveLdap %s or later")
    logger.error(format % required_version.join("."))
  end
end

ldap_configuration_file = File.join(RAILS_ROOT, 'config', 'ldap.yml')
if File.exist?(ldap_configuration_file)
  configurations = YAML::load(ERB.new(IO.read(ldap_configuration_file)).result)
  ActiveLdap::Base.configurations = configurations
  ActiveLdap::Base.establish_connection
else
  ActiveLdap::Base.class_eval do
    format = _("You should run 'script/generator scaffold_al' to make %s.")
    logger.error(format % ldap_configuration_file)
  end
end

if ActiveLdap.const_defined?(:Helper)
  class ActionView::Base
    include ActiveLdap::Helper
  end
end
