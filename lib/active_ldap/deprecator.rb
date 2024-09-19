module ActiveLdap
  class << self
    def deprecator # :nodoc:
      @deprecator ||= ActiveSupport::Deprecation.new
    end
  end
end
