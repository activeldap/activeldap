require "locale"
require 'active_ldap'
require 'rails'

Locale.init(:driver => :cgi)

module ActiveLdap
  class Railtie < Rails::Railtie
    initializer "active_ldap.deprecator", before: :load_environment_config do |app|
      app.deprecators[:active_ldap] = ActiveLdap.deprecator
    end

    initializer "active_ldap.setup_connection" do
      ldap_configuration_file = Rails.root.join('config', 'ldap.yml')
      if File.exist?(ldap_configuration_file)
        ActiveLdap::Base.configurations = ActiveSupport::ConfigurationFile.parse(ldap_configuration_file)
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
