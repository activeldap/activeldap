require 'active_ldap'
require 'rails'

module ActiveLdap
  class Railtie < Rails::Railtie
    config.generators.orm :active_ldap

    initializer "active_ldap.setup_connection" do
      ldap_configuration_file = Rails.root.join('config', 'ldap.yml')
      if File.exist?(ldap_configuration_file)
        configurations = YAML::load(ERB.new(IO.read(ldap_configuration_file)).result)
        ActiveLdap::Base.configurations = configurations
        ActiveLdap::Base.setup_connection
      else
        ActiveLdap::Base.class_eval do
          format =_("You should run 'script/generator scaffold_active_ldap' to make %s.")
          logger.error(format % ldap_configuration_file)
        end
      end
    end

    initializer "active_ldap.logger", :before => "active_ldap.setup_connection" do
      ActiveLdap::Base.logger ||= ::Rails.logger
    end

    initializer "active_ldap.actionview_helper" do
      class ::ActionView::Base
        include ActiveLdap::Helper
      end
    end

    #initializer "active_ldap.benchmarking" do
    #  require 'active_ldap/action_controller/ldap_benchmarking'
    #  module ::ActionController
    #    class Base
    #      include ActiveLdap::ActionController::LdapBenchmarking
    #    end
    #  end
    #end
  end
end
