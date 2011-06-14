# -*- ruby -*-

require 'thread'
require 'find'

require 'rubygems'
require 'bundler/setup'

require 'jeweler'
require 'rake/testtask'

if YAML.const_defined?(:ENGINE)
  begin
    YAML::ENGINE.yamler = "psych"
  rescue LoadError
  end
end

base_dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(base_dir, 'lib'))
require 'active_ldap'

ENV["VERSION"] ||= ActiveLdap::VERSION
version = ENV["VERSION"]
spec = nil
Jeweler::Tasks.new do |_spec|
  spec = _spec
  spec.name = 'activeldap'
  spec.version = version.dup
  spec.rubyforge_project = 'ruby-activeldap'
  spec.authors = ['Will Drewry', 'Kouhei Sutou']
  spec.email = ['redpig@dataspill.org', 'kou@cozmixng.org']
  spec.summary = 'ActiveLdap is a object-oriented API to LDAP'
  spec.homepage = 'http://ruby-activeldap.rubyforge.org/'
  spec.files = FileList["{lib,rails,rails_generators}/**/*",
                        "{benchmark,examples,po}/**",
                        "bin/*",
                        "CHANGES",
                        "COPYING",
                        "Gemfile",
                        "LICENSE",
                        "README",
                        "TODO",
                        "*.txt"]
  spec.test_files = FileList['test/test_*.rb']
  Bundler.load.dependencies_for(:default).each do |dependency|
    spec.add_runtime_dependency(dependency.name, dependency.requirement)
  end
  spec.description = <<-EOF
    'ActiveLdap' is a ruby extension library which provides a clean
    objected oriented interface to the Ruby/LDAP library.  It was inspired
    by ActiveRecord. This is not nearly as clean or as flexible as
    ActiveRecord, but it is still trivial to define new objects and manipulate
    them with minimal difficulty.
  EOF
end

Rake::TestTask.new(:test) do |test|
  test.libs << "lib"
  test.libs << "test"
  test.pattern = "test/**/test_*.rb"
end

begin
  require "gettext_i18n_rails/tasks"
rescue LoadError
  puts "gettext_i18n_rails is not installed, you probably should run 'rake gems:install' or 'bundle install'."
end

def rsync_to_rubyforge(spec, source, destination, options={})
  config = YAML.load(File.read(File.expand_path("~/.rubyforge/user-config.yml")))
  host = "#{config["username"]}@rubyforge.org"

  rsync_args = "-av --exclude '*.erb' --dry-run"
  rsync_args << " --delete" if options[:delete]
  remote_dir = "/var/www/gforge-projects/#{spec.rubyforge_name}/"
  sh("rsync #{rsync_args} #{source} #{host}:#{remote_dir}#{destination}")
end

desc "Publish HTML to Web site."
task :publish_html do
  rsync_to_rubyforge(spec, "doc/", "/#{spec.name}",
                     :delete => true)
end

desc "Tag the current revision."
task :tag do
  message = "Released ActiveLdap #{version}!"
  sh 'git', 'tag', '-a', version, '-m', message
end

# vim: syntax=ruby
