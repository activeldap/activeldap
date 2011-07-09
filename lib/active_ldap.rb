require "rubygems"
require "active_model"
require "active_support/core_ext"

module ActiveLdap
  VERSION = "3.1.1"
  autoload :Command, "active_ldap/command"
end

if RUBY_PLATFORM.match('linux')
  require 'active_ldap/timeout'
else
  require 'active_ldap/timeout_stub'
end

begin
  require "locale"
  require "fast_gettext"
rescue LoadError
end
require 'active_ldap/get_text'

require 'active_ldap/compatible'

require 'active_ldap/base'

require 'active_ldap/distinguished_name'
require 'active_ldap/ldif'
require 'active_ldap/xml'

require 'active_ldap/persistence'

require 'active_ldap/associations'
require 'active_ldap/attributes'
require 'active_ldap/configuration'
require 'active_ldap/connection'
require 'active_ldap/operations'
require 'active_ldap/object_class'
require 'active_ldap/human_readable'

require 'active_ldap/acts/tree'

require 'active_ldap/populate'
require 'active_ldap/escape'
require 'active_ldap/user_password'
require 'active_ldap/helper'

require 'active_ldap/validations'
require 'active_ldap/callbacks'


ActiveLdap::Base.class_eval do
  include ActiveLdap::Associations
  include ActiveLdap::Attributes
  include ActiveLdap::Configuration
  include ActiveLdap::Connection
  include ActiveLdap::Operations
  include ActiveLdap::ObjectClass

  include ActiveLdap::Persistence

  include ActiveLdap::Acts::Tree

  include ActiveLdap::Validations
  include ActiveLdap::Callbacks
  include ActiveLdap::HumanReadable
end

unless defined?(ACTIVE_LDAP_CONNECTION_ADAPTERS)
  ACTIVE_LDAP_CONNECTION_ADAPTERS = %w(ldap net_ldap jndi)
end

ACTIVE_LDAP_CONNECTION_ADAPTERS.each do |adapter|
  require "active_ldap/adapter/#{adapter}"
end

