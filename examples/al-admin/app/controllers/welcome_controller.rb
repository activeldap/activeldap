class WelcomeController < ApplicationController
  include UrlHelper

  def index
    redirect_to(:login_path) unless logged_in?
  end
end
