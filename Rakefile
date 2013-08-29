# -*- ruby -*-

require "thread"
require "find"
require "pathname"
require "erb"
require "yaml"

require "rubygems"
require "bundler/setup"

require "bundler/gem_helper"
require "packnga"

task :default => :test

project_name = "ActiveLdap"

base_dir = File.dirname(__FILE__)

helper = Bundler::GemHelper.new(base_dir)
def helper.version_tag
  version
end

helper.install
spec = helper.gemspec

version = spec.version.to_s

begin
  require "gettext_i18n_rails/tasks"
rescue LoadError
  puts "gettext_i18n_rails is not installed, you probably should run 'rake gems:install' or 'bundle install'."
end

Packnga::DocumentTask.new(spec) do |task|
  task.original_language = "en"
  task.translate_languages = ["ja"]
end

ranguba_org_dir = Dir.glob("{..,../../www}/activeldap.github.io").first
Packnga::ReleaseTask.new(spec) do |task|
  task.index_html_dir = ranguba_org_dir
end

desc "Run tests"
task :test do
  ruby("-I", "lib", "test/run-test.rb")
end

# vim: syntax=ruby
