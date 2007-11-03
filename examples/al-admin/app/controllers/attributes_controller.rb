class AttributesController < ApplicationController
  def index
    @attributes = schema.attributes
  end
end
