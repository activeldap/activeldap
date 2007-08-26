module ActionController
  class AbstractRequest
    def relative_url_root_with_accept_http_rails_relative_url_root
      @env["RAILS_RELATIVE_URL_ROOT"] ||= @env["HTTP_RAILS_RELATIVE_URL_ROOT"]
      relative_url_root_without_accept_http_rails_relative_url_root
    end
    alias_method_chain :relative_url_root, :accept_http_rails_relative_url_root
  end
end
