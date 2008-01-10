ActionController::Routing::Routes.draw do |map|
  lang_map = Proc.new do |*args|
    method, path, options = args
    duped_options = (options || {}).dup
    requirements = duped_options.delete(:requirements) || {}
    defaults = duped_options.delete(:defaults) || {}
    lang_options = {
      :requirements => {:lang => /(?:[a-z]{2,2})?/}.merge(requirements),
      :defaults => {},
    }
    lang_options[:defaults] = {:lang => nil} if method != :connect
    lang_options[:defaults].merge!(defaults)
    map.send(method, ":lang/#{path}", lang_options.merge(duped_options))
    map.send(:connect, *args[1..-1])
  end

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"
  lang_map.call(:top, '', :controller => "welcome")

  # See how all your routes lay out with "rake routes"

  lang_map.call(:connect, 'object_class/*id',
                :controller => "object_classes", :action => "show")
  lang_map.call(:connect, 'attribute/*id',
                :controller => "attributes", :action => "show")
  lang_map.call(:connect, 'syntax/*id',
                :controller => "syntaxes", :action => "show")

  # Install the default routes as the lowest priority.
  lang_map.call(:connect, ':controller/:action/:id')
  lang_map.call(:connect, ':controller/:action/:id.:format')
end
