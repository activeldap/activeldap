ActionController::Routing::Routes.draw do |map|

  lang_map = Proc.new do |*args|
    method, path, options = args
    duped_options = (options || {}).dup
    requirements = duped_options.delete(:requirements) || {}
    defaults = duped_options.delete(:defaults) || {}
    lang_options = {
      :requirements => {:lang => /[a-z]{2,2}/}.merge(requirements),
      :defaults => {},
    }
    lang_options[:defaults] = {:lang => nil} if method != :connect
    lang_options[:defaults].merge!(defaults)
    map.send(method, ":lang/#{path}", lang_options.merge(duped_options))
    map.send(:connect, *args[1..-1])
  end

  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  lang_map.call(:top, '', :controller => "welcome")

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  lang_map.call(:connect, ':controller/service.wsdl', :action => 'wsdl')

  # Install the default route as the lowest priority.
  lang_map.call(:connect, ':controller/:action/:id.:format')
  lang_map.call(:connect, ':controller/:action/:id')
end
