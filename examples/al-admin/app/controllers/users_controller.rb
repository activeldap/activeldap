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
    object_class_error_message = nil
    begin
      @user.replace_class(params["object-classes"])
    rescue ActiveLdap::RequiredObjectClassMissed
      object_class_error_message = $!.message
    end
    if @user.update_attributes(params[:user]) and
        object_class_error_message.nil?
      if previous_user_password != @user.user_password and @user.connected?
        @user.bind(@user.password)
      end
      flash[:notice] = _('User was successfully updated.')
      redirect_to :action => 'show', :id => @user
    else
      @user.password = @user.password_confirmation = nil
      @user.errors.add("objectClass", object_class_error_message)
      render :action => 'edit'
    end
  end

  def update_object_classes
    @user = find(params[:id])
    begin
      @user.replace_class(params["object-classes"])
    rescue ActiveLdap::RequiredObjectClassMissed
      flash.now[:inline_notice] = $!.message
      erb = "<%= flash_box(flash[:inline_notice], :need_container => true) %>"
      render(:inline => erb, :status => 400)
      return
    end
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
