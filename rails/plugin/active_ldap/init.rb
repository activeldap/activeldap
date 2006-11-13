require_dependency 'active_ldap'
ActiveLdap::Base.logger ||= RAILS_DEFAULT_LOGGER
ldap_configuration_file = File.join(RAILS_ROOT, 'config', 'ldap.yml')
configurations = YAML::load(ERB.new(IO.read(ldap_configuration_file)).result)
ActiveLdap::Base.configurations = configurations
ActiveLdap::Base.establish_connection
