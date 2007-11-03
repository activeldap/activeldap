class SyntaxesController < ApplicationController
  before_filter :login_required

  def index
    @syntaxes = schema.ldap_syntaxes
  end

  def show
    key = params[:id].to_a.flatten.compact[0]
    raise ActiveRecord::RecordNotFound if key.nil?
    @syntax = schema.ldap_syntaxes.find do |syntax|
      syntax.name == key or
        syntax.id == key
    end
    raise ActiveRecord::RecordNotFound if @syntax.nil?
  end
end
