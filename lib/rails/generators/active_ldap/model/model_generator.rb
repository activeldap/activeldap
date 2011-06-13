require 'rails/generators'
require 'active_ldap'

module ActiveLdap
  module Generators
    class ModelGenerator < Rails::Generators::NamedBase
      include ActiveLdap::GetTextSupport
      source_root File.expand_path('../templates', __FILE__)
      
      class_option :dn_attribute, :type => :string, :default => 'cn',
        :desc => _("Use ATTRIBUTE as default DN attribute for " \
                   "instances of this model")
      class_option :prefix, :type => :string,
        :desc => _("Use PREFIX as prefix for this model")
      class_option :classes, :type => :array, :default => nil,
        :desc => _("Use CLASSES as required objectClass for instances of this model")
      
      def create_model
        template 'model_active_ldap.rb', File.join('app/models', class_path, "#{file_name}.rb")
      end
      
      hook_for :test_framework, :as => :model
      
      private
      
      def prefix
        options[:prefix] || default_prefix
      end
      
      def default_prefix
        "ou=#{name.demodulize.pluralize}"
      end
      
      def ldap_mapping(indent='  ')
        mapping = "ldap_mapping "
        mapping_options = [":dn_attribute => #{options[:dn_attribute].dump}"]
        mapping_options << ":prefix => #{prefix.dump}"
        if options[:classes]
          mapping_options << ":classes => #{options[:classes].inspect}"
        end
        mapping_options = mapping_options.join(",\n#{indent}#{' ' * mapping.size}")
        "#{indent}#{mapping}#{mapping_options}"
      end
    end
  end
end

