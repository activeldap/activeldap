#!/usr/bin/env ruby

$VERBOSE = true

$KCODE = 'u' if RUBY_VERSION < "1.9"

require 'yaml'

base_dir = File.expand_path(File.dirname(__FILE__))
top_dir = File.expand_path(File.join(base_dir, ".."))
$LOAD_PATH.unshift(File.join(top_dir, "lib"))
$LOAD_PATH.unshift(File.join(top_dir, "test"))

$LOAD_PATH.unshift(File.join(top_dir, "test-unit", "lib"))
require "test/unit"
ARGV.unshift("--priority-mode")

test_file = "test/test_*.rb"
Dir.glob(test_file) do |file|
  require file
end

[nil, "ldap", "net-ldap"].each do |adapter|
  ENV["ACTIVE_LDAP_TEST_ADAPTER"] = adapter
  puts "using adapter: #{adapter ? adapter : 'default'}"
  args = [File.dirname($0), ARGV.dup]
  if Test::Unit::AutoRunner.respond_to?(:standalone?)
    args.unshift(false)
  else
    args.unshift($0)
  end
  Test::Unit::AutoRunner.run(*args)
  puts
end
