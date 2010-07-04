ActionController::Routing::Routes.draw do |map|
  map.resources :samples, :collection => {:clear_cookie => :get,
					  :cached_action => :get}

  # Localized Routing.
  map.connect '/:lang/:controller/:action/:id'
  map.connect '/:lang/:controller/:action/:id.:format'

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

  map.root :controller => "samples"
end
