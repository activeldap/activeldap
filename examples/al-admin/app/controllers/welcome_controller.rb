class WelcomeController < ApplicationController
  include UrlHelper

  def index
    unless logged_in?
      flash.keep(:notice)
      redirect_to(:login_path)
    end
  end
end
