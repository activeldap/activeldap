require 'rubygems'

spec = Gem::Specification.new do |s|
  s.add_dependency('log4r', '>= 1.0.4')
  s.name = 'ruby-activeldap'
  s.version = "0.8.0"
  s.platform = Gem::Platform::RUBY
  s.summary = "Ruby/ActiveLDAP is a object-oriented API to LDAP"
  s.requirements << '(Open)LDAP server'
  # Until such a time as Ruby/LDAP is gem'd, or I figure out how to do it :)
  s.requirements << 'ruby-ldap = 0.8.2'
  s.files = Dir.glob("lib/**/*").delete_if {|item| item.include?("CVS")}
  s.require_path = 'lib'
  s.autorequire = 'activeldap'
  s.author = "Will Drewry"
  s.email = "will@alum.bu.edu"
  s.rubyforge_project = "ruby-activeldap"
  s.homepage = "http://projects.dataspill.org/libraries/ruby/activeldap/index.html"
end

if $0==__FILE__
  Gem.manage_gems
  Gem::Builder.new(spec).build
end
