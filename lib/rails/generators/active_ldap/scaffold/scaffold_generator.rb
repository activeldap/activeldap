require 'rails/generators'

module ActiveLdap
  module Generators
    class ScaffoldGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)
      
      def create_ldap_yml
        copy_file 'ldap.yml', 'config/ldap.yml'
      end
    end
  end
end

