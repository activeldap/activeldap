# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_al-admin_session_id'

  init_gettext "al-admin"

  include ExceptionNotifiable

  include AuthenticatedSystem
  before_filter :check_connectivity
  before_filter :login_from_cookie

  private
  def default_url_options(options)
    default_options = {}
    lang = params["lang"]
    default_options["lang"] = lang if lang
    default_options.merge(options)
  end

  def schema
    @schema ||= current_ldap_user.schema
  end
end
