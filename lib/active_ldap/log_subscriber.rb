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
      @odd_or_even = false
    end
    
    def log_info(event)
      self.class.runtime += event.duration
      return unless logger.debug?
  
      payload = event.payload
      name = 'LDAP: %s (%.1fms)' % [payload[:name], event.duration]
      info = payload[:info].inspect
  
      if odd?
        name_color, dump_color = "4;36;1", "0;1"
      else
        name_color, dump_color = "4;35;1", "0"
      end
  
      debug "  \e[#{name_color}m#{name}\e[0m: \e[#{dump_color}m#{info}\e[0m"
    end
    
    def odd?
      @odd_or_even = !@odd_or_even
    end
    
    def logger
      ActiveLdap::Base.logger
    end
  end
end

ActiveLdap::LogSubscriber.attach_to :active_ldap


