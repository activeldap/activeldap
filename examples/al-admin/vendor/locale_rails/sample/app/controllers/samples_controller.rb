class SamplesController < ApplicationController
  caches_action :cached_action

  def index
  end

  def set_cookie
    flash[:notice] = "Cookie lang value is: " + params[:id]

    cookies["lang"] = params[:id]

    respond_to do |format|
      format.html { redirect_to :action => "index" }
    end
  end

  def clear_cookie
    cookies["lang"] = nil

    flash[:notice] = "Cookie lang value is cleared. "
    respond_to do |format|
      format.html { redirect_to :action => "index" }
    end
  end

  def cached_action
    p "cached_action. This is shown first time only."
  end
end

