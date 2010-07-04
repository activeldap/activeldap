=begin
  lib/locale_rails/action_controller.rb - Ruby/Locale for "Ruby on Rails"

  Copyright (C) 2008-2009  Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.

=end

require 'action_controller'
["base", "caching", "test_process"].each do  |lib|
  require File.join(File.dirname(__FILE__), "action_controller", lib)
end

