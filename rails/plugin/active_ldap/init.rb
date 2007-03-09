require_library_or_gem 'active_ldap'
ActiveLdap::Base.logger ||= RAILS_DEFAULT_LOGGER
ldap_configuration_file = File.join(RAILS_ROOT, 'config', 'ldap.yml')
if File.exist?(ldap_configuration_file)
  configurations = YAML::load(ERB.new(IO.read(ldap_configuration_file)).result)
  ActiveLdap::Base.configurations = configurations
  ActiveLdap::Base.establish_connection
else
  message = "You should run 'script/generator scaffold_al' " +
    "to make #{ldap_configuration_file}"
  ActiveLdap::Base.logger.error(message)
end
