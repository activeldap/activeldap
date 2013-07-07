require 'active_support/core_ext/array/wrap'

module ActiveLdap
  module Callbacks
    extend ActiveSupport::Concern

    CALLBACKS = [
      :after_initialize, :after_find, :after_touch, :before_validation, :after_validation,
      :before_save, :around_save, :after_save, :before_create, :around_create,
      :after_create, :before_update, :around_update, :after_update,
      :before_destroy, :around_destroy, :after_destroy, :after_commit, :after_rollback
    ]

    included do
      extend ActiveModel::Callbacks
      include ActiveModel::Validations::Callbacks
      
      define_model_callbacks :initialize, :find, :touch, :only => :after
      define_model_callbacks :save, :create, :update, :destroy
      
      class << self
        alias_method_chain :instantiate, :callbacks
      end
    end

    module ClassMethods
      def method_added(meth)
        super
        if CALLBACKS.include?(meth.to_sym)
          ActiveSupport::Deprecation.warn("Base##{meth} has been deprecated, please use Base.#{meth} :method instead", caller[0,1])
          send(meth.to_sym, meth.to_sym)
        end
      end
    end

    module ClassMethods
      def instantiate_with_callbacks(record)
        object = instantiate_without_callbacks(record)
        object.run_callbacks(:find)
        object.run_callbacks(:initialize)
        object
      end
    end

    def initialize(*) #:nodoc:
      run_callbacks(:initialize) { super }
    end

    def destroy #:nodoc:
      run_callbacks(:destroy) { super }
    end

    def touch(*) #:nodoc:
      run_callbacks(:touch) { super }
    end

  private

    def create_or_update #:nodoc:
      run_callbacks(:save) { super }
    end

    def create #:nodoc:
      run_callbacks(:create) { super }
    end

    def update(*) #:nodoc:
      run_callbacks(:update) { super }
    end
  end
end
