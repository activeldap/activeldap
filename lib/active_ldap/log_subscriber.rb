module ActiveLdap
  class LogSubscriber < ActiveSupport::LogSubscriber
    def self.runtime=(value)
      Thread.current["active_ldap_runtime"] = value
    end

    def self.runtime
      Thread.current["active_ldap_runtime"] ||= 0
    end

    def self.reset_runtime
      rt, self.runtime = runtime, 0
      rt
    end

    def log_info(event)
      self.class.runtime += event.duration
      return unless logger.debug?

      payload = event.payload
      name = 'LDAP: %s (%.1fms)' % [payload[:name], event.duration]
      info = payload[:info].inspect

      debug "#{name}: #{info}"
    end

    def logger
      ActiveLdap::Base.logger
    end
  end
end

ActiveLdap::LogSubscriber.attach_to :active_ldap


