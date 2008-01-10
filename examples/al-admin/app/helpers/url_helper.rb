module UrlHelper
  def login_path
    url_for(:controller => "/account", :action => "login")
  end

  def logout_path
    url_for(:controller => "/account", :action => "logout")
  end

  def sign_up_path
    url_for(:controller => "/account", :action => "sign_up")
  end

  def populate_path
    url_for(:controller => "/directory", :action => "populate")
  end
end
