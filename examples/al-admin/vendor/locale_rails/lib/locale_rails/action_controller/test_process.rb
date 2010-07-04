=begin
  lib/locale_rails/action_controller.rb - Ruby/Locale for "Ruby on Rails"

  Copyright (C) 2009  Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.

=end

require 'action_controller'
require 'action_controller/test_process'

module ActionController
  if defined? AbstractRequest  #:nodoc:
    # for Rails-2.2.x or earlier. 
    class TestRequest < AbstractRequest  #:nodoc:
      class LocaleMockCGI < CGI #:nodoc:
        attr_accessor :stdinput, :stdoutput, :env_table
        
        def initialize(env, input=nil)
          self.env_table = env
          self.stdinput = StringIO.new(input || "")
          self.stdoutput = StringIO.new
          
          super()
        end
      end

      @cgi = nil
      def cgi
        unless @cgi
          @cgi = LocaleMockCGI.new("REQUEST_METHOD" => "GET",
                                   "QUERY_STRING"   => "",
                                   "REQUEST_URI"    => "/",
                                   "HTTP_HOST"      => "www.example.com",
                                   "SERVER_PORT"    => "80",
                                   "HTTPS"          => "off")
        end
        @cgi
      end
    end
  end
end
