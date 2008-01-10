class WelcomeController < ApplicationController
  include UrlHelper

  def index
    if Entry.empty?
      redirect_to(populate_path)
    elsif !logged_in?
      flash.keep(:notice)
      redirect_to(login_path)
    end
  end
end
