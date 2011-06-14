require 'active_ldap'
require 'rails'

module ActiveLdap
  class Railtie < Rails::Railtie
    config.app_generators.orm :active_ldap

    initializer "active_ldap.setup_connection" do
      ldap_configuration_file = Rails.root.join('config', 'ldap.yml')
      if File.exist?(ldap_configuration_file)
        configurations = YAML::load(ERB.new(IO.read(ldap_configuration_file)).result)
        ActiveLdap::Base.configurations = configurations
        ActiveLdap::Base.setup_connection
      else
        ActiveLdap::Base.class_eval do
          format =_("You should run 'rails generator active_ldap:scaffold' to make %s.")
          logger.error(format % ldap_configuration_file)
        end
      end
    end

    initializer "active_ldap.logger", :before => "active_ldap.setup_connection" do
      ActiveLdap::Base.logger ||= ::Rails.logger
    end

    initializer "active_ldap.action_view_helper" do
      class ::ActionView::Base
        include ActiveLdap::Helper
      end
    end

    # Expose Ldap runtime to controller for logging.
    initializer "active_ldap.log_runtime" do |app|
      require "active_ldap/railties/controller_runtime"
      ActiveSupport.on_load(:action_controller) do
        include ActiveLdap::Railties::ControllerRuntime
      end
    end
  end
end
