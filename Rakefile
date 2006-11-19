# -*- ruby -*-

require 'rubygems'
require 'hoe'
$:<<'./lib'
require 'active_ldap'

Hoe.new('ruby-activeldap', ActiveLdap::VERSION) do |project|
  project.rubyforge_name = 'ruby-activeldap'
  project.author = ['Will Drewry', 'Kouhei Sutou']
  project.email = ['will@alum.bu.edu', 'kou@cozmixng.org']
  project.summary = 'Ruby/ActiveLdap is a object-oriented API to LDAP'
  project.url = 'http://rubyforge.org/projects/ruby-activeldap/'
  project.test_globs = ['test/**']
  project.changes = project.paragraphs_of('CHANGES', 0..1).join("\n\n")
  project.extra_deps = [['log4r','>= 1.0.4'], 'activerecord']
  project.spec_extras = {
    :requirements => ['ruby-ldap >= 0.8.2', '(Open)LDAP server'],
    :autorequire => 'active_ldap'
  }
  project.description = String.new(<<-EOF)
    'Ruby/ActiveLdap' is a ruby extension library which provides a clean
    objected oriented interface to the Ruby/LDAP library.  It was inspired
    by ActiveRecord. This is not nearly as clean or as flexible as
    ActiveRecord, but it is still trivial to define new objects and manipulate
    them with minimal difficulty.
  EOF
end

desc 'Tag the repository for release.'
task :tag do
  system "svn copy -m 'New release tag' https://ruby-activeldap.googlecode.com/svn/trunk https://ruby-activeldap.googlecode.com/svn/tags/r#{ActiveLdap::VERSION}"
end



# vim: syntax=Ruby
