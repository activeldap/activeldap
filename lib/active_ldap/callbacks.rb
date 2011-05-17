require 'active_record/callbacks'

module ActiveLdap
  module Callbacks
    def self.append_features(base)
      super

      base.class_eval do
        include ActiveRecord::Callbacks

        unless respond_to?(:instantiate_with_callbacks)
          extend ClassMethods
          class << self
            alias_method_chain :instantiate, :callbacks
          end
          alias_method_chain :initialize, :callbacks
        end
      end
    end

    module ClassMethods
      def instantiate_with_callbacks(record)
        object = instantiate_without_callbacks(record)
        object.send(:_run_find_callbacks)
        object.send(:_run_initialize_callbacks)
        object
      end
    end

    def initialize_with_callbacks(attributes = nil) #:nodoc:
      initialize_without_callbacks(attributes)
      result = yield self if block_given?
      _run_initialize_callbacks
      result
    end
  end
end
