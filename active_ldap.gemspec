# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require 'active_ldap/version'
 
Gem::Specification.new do |s|
  s.name        = "active_ldap"
  s.version     = ActiveLdap::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Will Drewry", "Kouhei Sutou"]
  s.email       = ["will@alum.bu.edu","kou@clear-code.com"]
  s.homepage    = "https://github.com/activeldap/activeldap"
  s.summary     = "ActiveLdap provides an object oriented interface to LDAP"
  s.description = "‘ActiveLdap’ is a ruby library which provides a clean objected oriented interface to LDAP library. It was inspired by ActiveRecord. This is not nearly as clean or as flexible as ActiveRecord, but it is still trivial to define new objects and manipulate them with minimal difficulty"
 
  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "activeldap"
 
  s.add_dependency "ruby-ldap"
 
  s.files        = Dir.glob("{lib}/**/*") + %w(LICENSE README.textile TODO)
  s.require_path = 'lib'
end
