module ActiveLdap
  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new("7.1.0", "ActiveLdap")
  end
end
