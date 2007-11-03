class AccountController < ApplicationController
  before_filter :force_logout, :only => [:sign_up, :login, :logout]

  def index
    if logged_in?
      redirect_to(top_path)
    else
      redirect_to(:action => 'login')
    end
  end

  def login
    return unless request.post?
    self.current_user = User.authenticate(params[:login], params[:password])
    if logged_in?
      if params[:remember_me] == "1"
        current_user.remember_me
        cookies[:auth_token] = {
          :value => current_user.remember_token,
          :expires => current_user.remember_token_expires_at
        }
      end
      redirect_back_or_default(top_url)
      flash[:notice] = _("Logged in successfully")
    else
      flash[:notice] = _("Login or Password is incorrect")
    end
  end

  def sign_up
    @user = LdapUser.new(params[:user])
    @required_attributes = @user.must.collect(&:name)
    return unless request.post?

    if @user.save
      @system_user = User.create(:login => @user.id)
      unless @system_user.new_record?
        self.current_user = @system_user
        redirect_back_or_default(top_path)
        flash[:notice] = _("Thanks for signing up!")
      end
    end
    @user.password = @user.password_confirmation = nil
  end

  def logout
    flash[:notice] = _("You have been logged out.")
    redirect_back_or_default(top_path)
  end

  private
  def force_logout
    current_user.forget_me if logged_in?
    self.current_user = nil
    cookies.delete :auth_token
    reset_session
    true
  end
end
