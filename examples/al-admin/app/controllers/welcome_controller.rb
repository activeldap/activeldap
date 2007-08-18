class WelcomeController < ApplicationController
  def index
    redirect_to(login_path) unless logged_in?
  end
end
