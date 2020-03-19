# -*- ruby -*-

source "http://rubygems.org"

gemspec

group :development do
  gem "RedCloth", platform: :mri
end

group :test do
  gem "net-ldap"
  platforms :mri do
    gem "ruby-ldap"
  end
  platforms :jruby do
    gem "jruby-openssl"
  end
end
