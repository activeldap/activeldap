# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
#RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.time_zone = 'UTC'

  config.action_controller.session = {
    :session_key => '_rails_session',
    :secret      => '25fe1cb0e4295d9ede3b21864a1a3b589a4656bd0032fee8b8a470a93d221d4d666e9076a35bd0e4fd0fe8ca12eec9dc85f46554cd6e26b4569548b6ee03323a'
  }

  config.gem "locale"
  config.gem "locale_rails"
end

ActionController::Base.cache_store = :file_store, "#{RAILS_ROOT}/tmp/cache"
