# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '639df270d82028344f5a50f543530c57'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password

  # Set the charset of Content-Type.
  # This is not Ruby-Locale method but useful.
#  self.default_charset = "iso8859-1"
  # I18n.supported_locales = ["en", "ja", "fr"]

=begin
  def before_init_i18n
    # Initialize other i18n libraries before init_locale if you need.
    # Or set "lang" to it's own value before initializing Locale.
    if (cookies["lang"].nil? or cookies["lang"].empty?)
      params["lang"] = "ko_KR"
    end
  end
  before_init_locale :before_init_i18n

  def after_init_i18n
    # Initialize other i18n libraries after init_locale if you need.
    #
    # LocalizeFoo.locale = Locale.current
    # I18n.locale is set in init_locale, but other I18n features
    # is not set by Ruby-Locale. So you may need to add the code to work your
    # Rails i18n plugins.
  end
  after_init_locale :after_init_i18n
=end

end
