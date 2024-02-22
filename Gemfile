# -*- ruby -*-

source "http://rubygems.org"

gemspec

group :test do
  gem "net-ldap"
  platforms :mri do
    gem "ruby-ldap" if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("3.2.0")
  end
  platforms :jruby do
    gem "jruby-openssl"
  end
end
