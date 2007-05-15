# -*- ruby -*-

require 'rubygems'
require 'hoe'
$LOAD_PATH.unshift('./lib')
require 'active_ldap'

project = Hoe.new('ruby-activeldap', ActiveLdap::VERSION) do |project|
  project.rubyforge_name = 'ruby-activeldap'
  project.author = ['Will Drewry', 'Kouhei Sutou']
  project.email = ['will@alum.bu.edu', 'kou@cozmixng.org']
  project.summary = 'Ruby/ActiveLdap is a object-oriented API to LDAP'
  project.url = 'http://rubyforge.org/projects/ruby-activeldap/'
  project.test_globs = ['test/test_*.rb']
  project.changes = project.paragraphs_of('CHANGES', 0..1).join("\n\n")
  project.extra_deps = [['log4r', '>= 1.0.4'], 'activerecord']
  project.spec_extras = {
    :requirements => ['ruby-ldap >= 0.8.2', '(Open)LDAP server'],
    :autorequire => 'active_ldap',
    :executables => [],
  }
  project.description = String.new(<<-EOF)
    'Ruby/ActiveLdap' is a ruby extension library which provides a clean
    objected oriented interface to the Ruby/LDAP library.  It was inspired
    by ActiveRecord. This is not nearly as clean or as flexible as
    ActiveRecord, but it is still trivial to define new objects and manipulate
    them with minimal difficulty.
  EOF
end

# fix Hoe's incorrect guess.
project.spec.executables.clear
project.bin_files = project.spec.files.grep(/^bin/)

# fix Hoe's install and uninstall task.
task(:install).instance_variable_get("@actions").clear
task(:uninstall).instance_variable_get("@actions").clear

task :install do
  [
   [project.lib_files, "lib", Hoe::RUBYLIB, 0444],
   [project.bin_files, "bin", File.join(Hoe::PREFIX, 'bin'), 0555]
  ].each do |files, prefix, dest, mode|
    FileUtils.mkdir_p dest unless test ?d, dest
    files.each do |file|
      base = File.dirname(file.sub(/^#{prefix}#{File::SEPARATOR}/, ''))
      _dest = File.join(dest, base)
      FileUtils.mkdir_p _dest unless test ?d, _dest
      install file, _dest, :mode => mode
    end
  end
end

desc 'Uninstall the package.'
task :uninstall do
  Dir.chdir Hoe::RUBYLIB do
    rm_f project.lib_files.collect {|f| f.sub(/^lib#{File::SEPARATOR}/, '')}
  end
  Dir.chdir File.join(Hoe::PREFIX, 'bin') do
    rm_f project.bin_files.collect {|f| f.sub(/^bin#{File::SEPARATOR}/, '')}
  end
end


desc 'Tag the repository for release.'
task :tag do
  system "svn copy -m 'New release tag' https://ruby-activeldap.googlecode.com/svn/trunk https://ruby-activeldap.googlecode.com/svn/tags/r#{ActiveLdap::VERSION}"
end

# vim: syntax=ruby
