# -*- ruby -*-

source "http://rubygems.org"

gemspec

group :test do
  gem "net-ldap"
  platforms :mri_18, :mri_19 do
    gem "ruby-ldap"
  end
end
