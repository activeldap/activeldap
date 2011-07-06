#!/usr/bin/env ruby

$VERBOSE = true

$KCODE = 'u' if RUBY_VERSION < "1.9"

base_dir = File.expand_path(File.dirname(__FILE__))
top_dir = File.expand_path(File.join(base_dir, ".."))
$LOAD_PATH.unshift(File.join(top_dir))
$LOAD_PATH.unshift(File.join(top_dir, "lib"))
$LOAD_PATH.unshift(File.join(top_dir, "test"))


require "test/unit"
require "test/unit/notify"
Test::Unit::Priority.enable

target_adapters = [ENV["ACTIVE_LDAP_TEST_ADAPTER"]]
# target_adapters << "ldap"
# target_adapters << "net-ldap"
# target_adapters << "jndi"
target_adapters.each do |adapter|
  ENV["ACTIVE_LDAP_TEST_ADAPTER"] = adapter
  puts "using adapter: #{adapter ? adapter : 'default'}"
  Test::Unit::AutoRunner.run(true, File.dirname($0), ARGV.dup)
  puts
end
