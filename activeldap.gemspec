# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name = "activeldap"
  s.version = '1.2.2.1'
  s.platform = Gem::Platform::RUBY
  s.authors = ["Will Drewry", "Kouhei Sutou", "koutou", "Kenny Ortmann"]
  s.email = ['kenny.ortmann@gmail.com']
  s.homepage = "https://github.com/asynchrony/ruby-activeldap"
  s.summary = %q{1.2.2 patched to work wtih 2.3.11 rails}
  s.description = %q{1.2.2 patched to work with 2.3.11 rails}

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib", "po"]
end
