class AttributesController < ApplicationController
  before_filter :login_required

  def index
    @attributes = schema.attributes
  end

  def show
    key = params[:id].to_a.flatten.compact[0]
    raise ActiveRecord::RecordNotFound if key.nil?
    @attribute = schema.attributes.find do |attribute|
      attribute.name == key or
        attribute.id == key
    end
    raise ActiveRecord::RecordNotFound if @attribute.nil?
  end
end
