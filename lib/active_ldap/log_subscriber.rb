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

    def initialize
      super
      @odd = false
    end

    def log_info(event)
      self.class.runtime += event.duration
      return unless logger.debug?

      payload = event.payload
      info = payload[:info] || {}
      label = payload[:name]
      label += ": FAILED" if info[:exception]
      name = 'LDAP: %s (%.1fms)' % [label, event.duration]
      inspected_info = info.inspect

      formatting_options = 
        if ActiveSupport.version >= Gem::Version.new('7.1.0')
          { bold: true }
        else
          # Fallback for ActiveSupport < 7.1.0
          true
        end

      if odd?
        name = color(name, CYAN, formatting_options)
        inspected_info = color(inspected_info, nil, formatting_options)
      else
        name = color(name, MAGENTA, formatting_options)
      end

      debug "  #{name} #{inspected_info}"
    end

    def odd?
      @odd = !@odd
    end

    def logger
      ActiveLdap::Base.logger
    end
  end
end

ActiveLdap::LogSubscriber.attach_to :active_ldap


