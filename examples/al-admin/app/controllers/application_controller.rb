# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '5965eefc93d824a9c145fe8edb6d1a36'

  after_init_locale do |controller|
    (Thread.current[:current_request] || {})[:accept_charset] = nil
  end
  init_gettext "al-admin"

  include ExceptionNotifiable

  include AuthenticatedSystem
  before_filter :login_from_cookie

  filter_parameter_logging :password, :password_confirmation

  private
  def default_url_options(options)
    default_options = {}
    lang = params["lang"]
    default_options["lang"] = lang if lang
    default_options.merge(options)
  end

  def current_ldap_user
    logged_in? ? current_user.ldap_user : nil
  end

  def schema
    @schema ||= current_ldap_user.schema
  end

  def authorized?
    current_ldap_user.connected?
  end
end
