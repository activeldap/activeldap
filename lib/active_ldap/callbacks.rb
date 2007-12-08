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

        def callback(method)
          super
        rescue ActiveRecord::ActiveRecordError
          raise Error, $!.message
        end
      end
    end

    module ClassMethods
      def instantiate_with_callbacks(record)
        object = instantiate_without_callbacks(record)

        if object.respond_to_without_attributes?(:after_find)
          object.send(:callback, :after_find)
        end

        if object.respond_to_without_attributes?(:after_initialize)
          object.send(:callback, :after_initialize)
        end

        object
      end
    end

    def initialize_with_callbacks(attributes = nil) #:nodoc:
      initialize_without_callbacks(attributes)
      result = yield self if block_given?
      if respond_to_without_attributes?(:after_initialize)
        callback(:after_initialize)
      end
      result
    end
  end
end
