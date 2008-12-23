# GetText doesn't support Rails 2.2.2 yet. :<
# require 'gettext/rails'

class ::ActionController::Base
  include ActiveLdap::GetText

  class << self
    def init_gettext(*args)
    end
  end
end

class ::ActionView::Base
  include ActiveLdap::GetText
end
