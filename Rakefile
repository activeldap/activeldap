# -*- ruby -*-

require 'rubygems'
require 'hoe'
require 'find'

base_dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(base_dir, 'lib'))
require 'active_ldap'

truncate_base_dir = Proc.new do |x|
  x.gsub(/\A#{Regexp.escape(base_dir + File::SEPARATOR)}/, '')
end

manifest = File.join(base_dir, "Manifest.txt")
manifest_contents = []
base_dir_included_components = %w(CHANGES COPYING LICENSE Manifest.txt
                                  README Rakefile TODO)
excluded_components = %w(.svn .test-result .config doc log tmp
                         pkg html config.yaml database.yml ldap.yml)
excluded_suffixes = %w(.help .sqlite3)
white_list_paths =
  [
   "rails/plugin/active_ldap/generators/scaffold_al/templates/ldap.yml"
  ]
Find.find(base_dir) do |target|
  target = truncate_base_dir[target]
  components = target.split(File::SEPARATOR)
  if components.size == 1 and !File.directory?(target)
    next unless base_dir_included_components.include?(components[0])
  end
  unless white_list_paths.include?(target)
    Find.prune if (excluded_components - components) != excluded_components
    next if excluded_suffixes.include?(File.extname(target))
  end
  manifest_contents << target if File.file?(target)
end

File.open(manifest, "w") do |f|
  f.puts manifest_contents.sort.join("\n")
end
at_exit do
  FileUtils.rm_f(manifest)
end


project = Hoe.new('activeldap', ActiveLdap::VERSION) do |project|
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

publish_docs_actions = task(:publish_docs).instance_variable_get("@actions")
original_project_name = nil
before_publish_docs = Proc.new do
  original_project_name = project.name
  project.name = "doc"
end
after_publish_docs = Proc.new do
  project.name = original_project_name
end
publish_docs_actions.unshift(before_publish_docs)
publish_docs_actions.push(after_publish_docs)

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


desc "Update *.po/*.pot files and create *.mo from *.po files"
task :gettext => ["gettext:po:update", "gettext:mo:create"]

namespace :gettext do
  desc "Setup environment for GetText"
  task :environment do
    require "gettext/utils"
  end

  namespace :po do
    desc "Update po/pot files (GetText)"
    task :update => "gettext:environment" do
      require 'active_ldap/get_text/parser'
      dummy_file = "@@@dummy-for-active-ldap@@@"
      parser = Object.new
      parser.instance_eval do
        @parser = ActiveLdap::GetText::Parser.new
        @dummy_file = dummy_file
      end
      def parser.target?(file)
        file == @dummy_file
      end
      def parser.parse(file, targets)
        @parser.extract_all_in_schema(targets)
      end

      GetText::RGetText.add_parser(parser)
      files = [dummy_file] + Dir.glob("{lib,rails,benchmark}/**/*.rb")
      GetText.update_pofiles("active-ldap",
                             files,
                             "Ruby/ActiveLdap #{ActiveLdap::VERSION}")
    end
  end

  namespace :mo do
    desc "Create *.mo from *.po (GetText)"
    task :create => "gettext:environment" do
      GetText.create_mofiles(false)
    end
  end
end

task(:gem).prerequisites.unshift("gettext:mo:create")

# vim: syntax=ruby
