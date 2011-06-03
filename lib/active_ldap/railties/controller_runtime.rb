require 'active_support/core_ext/module/attr_internal'
require 'active_ldap/log_subscriber'

module ActiveLdap
  module Railties
    module ControllerRuntime #:nodoc:
      extend ActiveSupport::Concern
      
    protected
      
      attr_internal :ldap_runtime
      
      def process_action(action, *args)
        # We also need to reset the runtime before each action
        # because of queries in middleware or in cases we are streaming
        # and it won't be cleaned up by the method below.
        ActiveLdap::LogSubscriber.reset_runtime
        super
      end
      
      def cleanup_view_runtime
        if ActiveLdap::Base.connected?
          ldap_rt_before_render = ActiveLdap::LogSubscriber.reset_runtime
          runtime = super
          ldap_rt_after_render = ActiveLdap::LogSubscriber.reset_runtime
          self.ldap_runtime = ldap_rt_before_render + ldap_rt_after_render
          runtime - ldap_rt_after_render
        else
          super
        end
      end
      
      def append_info_to_payload(payload)
        super
        payload[:ldap_runtime] = ldap_runtime
      end
      
      module ClassMethods
        def log_process_action(payload)
          messages, ldap_runtime = super, payload[:ldap_runtime]
          messages << ("ActiveLdap: %.1fms" % ldap_runtime.to_f) if ldap_runtime
          messages
        end
      end
    end
  end
end

