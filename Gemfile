# -*- ruby -*-

source "http://rubygems.org"

gemspec

group :test do
  gem "net-ldap"
  platforms :mri do
    gem "ruby-ldap"
  end
  platforms :jruby do
    gem "jruby-openssl"
  end
end
