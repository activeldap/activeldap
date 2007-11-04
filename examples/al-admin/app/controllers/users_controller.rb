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

  private
  def find(*args)
    current_ldap_user.find(*args)
  end
end
