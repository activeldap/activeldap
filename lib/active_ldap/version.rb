module ActiveLdap
  # We're doing this because we might write tests that deal
  # with other versions of bundler and we are unsure how to
  # handle this better.
  VERSION = "3.1.1" unless defined?(::ActiveLdap::VERSION)
end