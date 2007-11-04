class UsersController < ApplicationController
  verify :method => :post, :only => [:update],
         :redirect_to => {:action => :index}

  before_filter :login_required

  def index
    @users = find(:all)
  end

  def show
    @user = find(params[:id])
  end

  def edit
    @user = find(params[:id])
  end

  def update
    @user = find(params[:id])
    previous_user_password = @user.user_password
    @user.replace_class(params["object-classes"])
    if @user.update_attributes(params[:user])
      if previous_user_password != @user.user_password and @user.connected?
        @user.bind(@user.password)
      end
      flash[:notice] = _('User was successfully updated.')
      redirect_to :action => 'show', :id => @user
    else
      @user.password = @user.password_confirmation = nil
      render :action => 'edit'
    end
  end

  def update_object_classes
    @user = find(params[:id])
    @user.replace_class(params["object-classes"])
    available_attributes = @user.attribute_names(true)
    attributes = {}
    (params[:user] || {}).each do |key, value|
      attributes[key] = value if available_attributes.include?(key)
    end
    @user.attributes = attributes
    render(:partial => "attributes_update_form")
  end

  private
  def find(*args)
    current_ldap_user.find(*args)
  end
end
