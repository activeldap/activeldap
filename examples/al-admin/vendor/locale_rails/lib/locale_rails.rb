require 'locale'

Locale.init(:driver => :cgi)

["i18n", "action_controller", "action_view", "version"].each do  |lib|
  require File.join(File.dirname(__FILE__), "locale_rails", lib)
end

begin
  Rails::Info.property("Locale version") do
    Locale::VERSION
  end
  Rails::Info.property("Locale for Rails version") do
    Locale::LOCALE_RAILS_VERSION
  end
rescue Exception
  $stderr.puts "Locale's Rails::Info is not found." if $DEBUG
end
