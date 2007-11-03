class ObjectClassesController < ApplicationController
  before_filter :login_required

  def index
    @object_classes = schema.object_classes
  end

  def show
    key = params[:id]
    @object_class = schema.object_classes.find do |object_class|
      object_class.name == key or
        object_class.id == key
    end
    raise ActiveRecord::RecordNotFound if @object_class.nil?
  end

  private
  def schema
    @schema ||= current_ldap_user.schema
  end
end
