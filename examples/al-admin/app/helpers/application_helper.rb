# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def sign_up_path
    url_for(:controller => "/account", :action => "sign_up")
  end
end
