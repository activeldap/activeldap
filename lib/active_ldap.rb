require "active_model"
require "active_support/core_ext"

require "active_ldap/version"

module ActiveLdap
  autoload :Command, "active_ldap/command"
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
require 'active_ldap/attribute_methods'
require 'active_ldap/attribute_methods/query'
require 'active_ldap/attribute_methods/before_type_cast'
require 'active_ldap/attribute_methods/read'
require 'active_ldap/attribute_methods/write'
require 'active_ldap/attribute_methods/dirty'
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
  include ActiveLdap::Persistence

  include ActiveLdap::Associations
  include ActiveModel::ForbiddenAttributesProtection
  include ActiveLdap::Attributes
  include ActiveLdap::AttributeMethods
  include ActiveLdap::AttributeMethods::BeforeTypeCast
  include ActiveLdap::AttributeMethods::Write
  include ActiveLdap::AttributeMethods::Dirty
  include ActiveLdap::AttributeMethods::Query
  include ActiveLdap::AttributeMethods::Read
  include ActiveLdap::Configuration
  include ActiveLdap::Connection
  include ActiveLdap::Operations
  include ActiveLdap::ObjectClass

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

require "active_ldap/entry"
require "active_ldap/railtie" if defined?(Rails)
