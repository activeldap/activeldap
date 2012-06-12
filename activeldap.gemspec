# -*- mode: ruby; coding: utf-8 -*-

Gem::Specification.new do |spec|
  base_dir = File.expand_path(File.dirname(__FILE__))
  $LOAD_PATH.unshift(File.join(base_dir, 'lib'))
  require 'active_ldap/version'

  collect_files = lambda do |*globs|
    files = []
    globs.each do |glob|
      files.concat(Dir.glob(glob))
    end
    files.uniq.sort
  end

  spec.name = 'activeldap'
  spec.version = ActiveLdap::VERSION.dup
  spec.rubyforge_project = 'ruby-activeldap'
  spec.authors = ['Will Drewry', 'Kouhei Sutou']
  spec.email = ['redpig@dataspill.org', 'kou@cozmixng.org']
  spec.summary = 'ActiveLdap is a object-oriented API to LDAP'
  spec.homepage = 'http://ruby-activeldap.rubyforge.org/'
  spec.files = collect_files.call("lib/**/*",
                                  "{benchmark,examples,po}/**/*",
                                  "bin/*",
                                  "doc/text/**/*",
                                  "COPYING",
                                  "Gemfile",
                                  "LICENSE",
                                  "README.textile",
                                  "TODO")
  spec.files.delete_if {|file| /\.yaml\z/ =~ File.basename(file)}
  spec.test_files = collect_files.call("test/**/*.rb",
                                       "test/config.yaml.sample",
                                       "test/**/*.ldif")
  spec.description = <<-EOF
    'ActiveLdap' is a ruby library which provides a clean
    objected oriented interface to the Ruby/LDAP library.  It was inspired
    by ActiveRecord. This is not nearly as clean or as flexible as
    ActiveRecord, but it is still trivial to define new objects and manipulate
    them with minimal difficulty.
  EOF
  spec.license = "Ruby's or GPLv2 or later"

  spec.add_dependency("activemodel", ["~> 3.1"])
  spec.add_dependency("locale")
  spec.add_dependency("fast_gettext")
  spec.add_dependency("gettext_i18n_rails")

  spec.add_development_dependency("ruby-ldap")
  spec.add_development_dependency("net-ldap")
  spec.add_development_dependency("jeweler")
  spec.add_development_dependency("test-unit")
  spec.add_development_dependency("test-unit-notify")
  spec.add_development_dependency("yard")
  spec.add_development_dependency("RedCloth")
end
