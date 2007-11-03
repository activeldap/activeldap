class ObjectClassesController < ApplicationController
  def index
    @object_classes = current_ldap_user.schema.object_classes
  end
end
