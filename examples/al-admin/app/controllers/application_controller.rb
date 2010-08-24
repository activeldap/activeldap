# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '5965eefc93d824a9c145fe8edb6d1a36'

  include ExceptionNotifiable

  include AuthenticatedSystem

  before_filter :login_from_cookie

  before_filter :set_gettext_locale

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

  def set_gettext_locale
    FastGettext.text_domain = 'al-admin'
    FastGettext.available_locales = ['en', 'ja', 'nl']
    super
  end
end
