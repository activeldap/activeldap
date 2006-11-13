require 'active_record/callbacks'

module ActiveLdap
  module Callbacks
    def self.append_features(base)
      super

      base.class_eval do
        include ActiveRecord::Callbacks

        def callback(method)
          super
        rescue ActiveRecord::ActiveRecordError
          raise Error, $!.message
        end
      end
    end
  end
end
