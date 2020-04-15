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
  spec.authors = ['Will Drewry', 'Kouhei Sutou']
  spec.email = ['redpig@dataspill.org', 'kou@cozmixng.org']
  spec.summary = 'ActiveLdap is a object-oriented API to LDAP'
  spec.homepage = 'http://activeldap.github.io/'
  spec.files = collect_files.call("lib/**/*",
                                  "{benchmark,examples,po}/**/*",
                                  "bin/*",
                                  ".yardopts",
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
  spec.licenses = ["Ruby's", "GPLv2 or later"]

  spec.add_dependency("activemodel", [">= 5.2"])
  spec.add_dependency("locale")
  spec.add_dependency("gettext")
  spec.add_dependency("gettext_i18n_rails")
  spec.add_dependency("builder")

  spec.add_development_dependency("bundler")
  spec.add_development_dependency("kramdown")
  spec.add_development_dependency("packnga")
  spec.add_development_dependency("rake")
  spec.add_development_dependency("test-unit")
  spec.add_development_dependency("yard")
end
