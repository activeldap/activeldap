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
   "rails/plugin/active_ldap/generators/scaffold_al/templates/ldap.yml",
   "rails_generators/scaffold_active_ldap/templates/ldap.yml",
  ]
Find.find(base_dir + File::SEPARATOR) do |target|
  target = truncate_base_dir[target]
  components = target.split(File::SEPARATOR)
  next if components.empty?
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

# For Hoe's no user friendly default behavior. :<
File.open("README.txt", "w") {|file| file << "= Dummy README\n== XXX\n"}
FileUtils.cp("CHANGES", "History.txt")
at_exit do
  FileUtils.rm_f("README.txt")
  FileUtils.rm_f("History.txt")
end

project = Hoe.spec('activeldap') do
  self.version = ActiveLdap::VERSION
  self.rubyforge_name = 'ruby-activeldap'
  self.author = ['Will Drewry', 'Kouhei Sutou']
  self.email = ['redpig@dataspill.org', 'kou@cozmixng.org']
  self.summary = 'Ruby/ActiveLdap is a object-oriented API to LDAP'
  self.url = 'http://rubyforge.org/projects/ruby-activeldap/'
  self.test_globs = ['test/test_*.rb']
  self.changes = self.paragraphs_of('CHANGES', 0..1).join("\n\n")
  self.extra_deps = [
                     'ruby-ldap = 0.9.9',
                     'activerecord = 2.3.2',
                     'locale = 2.0.4',
                     'gettext = 2.0.4',
                     'gettext_activerecord = 2.0.4',
                    ]
  self.remote_rdoc_dir = "doc"
  self.rsync_args += " --chmod=Dg+ws,Fg+w"
  self.spec_extras = {
    :autorequire => 'active_ldap',
    :executables => [],
  }
  self.description = String.new(<<-EOF)
    'Ruby/ActiveLdap' is a ruby extension library which provides a clean
    objected oriented interface to the Ruby/LDAP library.  It was inspired
    by ActiveRecord. This is not nearly as clean or as flexible as
    ActiveRecord, but it is still trivial to define new objects and manipulate
    them with minimal difficulty.
  EOF
end

project.spec.extra_rdoc_files = ["README", "CHANGES", "COPYING", "LICENSE"]

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


rdoc_main = "lib/active_ldap.rb"
project.spec.rdoc_options.each do |option|
  option.replace(rdoc_main) if option == "README.txt"
end
ObjectSpace.each_object(Rake::RDocTask) do |task|
  task.main = rdoc_main if task.main == "README.txt"
  task.rdoc_files = project.spec.require_paths + project.spec.extra_rdoc_files
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
    require "gettext/tools"
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
      GetText.create_mofiles
    end
  end
end

task(:gem).prerequisites.unshift("gettext:mo:create")

# vim: syntax=ruby
