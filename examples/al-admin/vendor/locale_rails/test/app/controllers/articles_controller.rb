class ArticlesController < ApplicationController
  caches_action :list
  def index
  end

  def list
  end

  def expire_cache
    expire_action(:action => "list")
    render :text => "OK"
  end

  def show
    render :action => 'show.html'
  end
end
