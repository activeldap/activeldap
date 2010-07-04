=begin
  lib/locale_rails/action_controller/base.rb - Ruby/Locale for "Ruby on Rails"

  Copyright (C) 2008-2009  Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.
=end

require 'action_controller'

module ActionController #:nodoc:
  class Base
    prepend_before_filter :init_locale

    def self.locale_filter_chain # :nodoc:
      if chain = read_inheritable_attribute('locale_filter_chain')
        return chain
      else
        write_inheritable_attribute('locale_filter_chain', FilterChain.new)
        return locale_filter_chain
      end
    end

    def init_locale # :nodoc:
      cgi = nil
      if defined? ::Rack
        cgi = request
      else
        if defined? request.cgi
          cgi = request.cgi
        end
      end

      fchain = self.class.locale_filter_chain
      run_before_filters(fchain.select(&:before?), 0, 0)

      cgi.params["lang"] = [params["lang"]] if params["lang"].is_a?(String)
      Locale.set_cgi(cgi)
      if cgi.params["lang"]
        I18n.locale = cgi.params["lang"][0]
      else
        I18n.locale = nil
      end

      run_after_filters(fchain.select(&:after?), 0)
    end

    # Append a block which is called before initializing locale on each WWW request.
    #
    # (e.g.)
    #   class ApplicationController < ActionController::Base
    #     def before_init_i18n
    #       if (cookies["lang"].nil? or cookies["lang"].empty?)
    #         params["lang"] = "ko_KR"
    #       end
    #     end
    #     before_init_locale :before_init_i18n
    #     # ...
    #   end
    def self.before_init_locale(*filters, &block)
      locale_filter_chain.append_filter_to_chain(filters, :before, &block)
    end

    # Append a block which is called after initializing locale on each WWW request.
    #
    # (e.g.)
    #   class ApplicationController < ActionController::Base
    #     def after_init_i18n
    #       L10nClass.new(Locale.candidates)
    #     end
    #     after_init_locale :after_init_i18n
    #     # ...
    #   end
    def self.after_init_locale(*filters, &block)
      locale_filter_chain.append_filter_to_chain(filters, :after, &block)
    end
  end

end


