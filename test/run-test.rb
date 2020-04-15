#!/usr/bin/env ruby

$VERBOSE = true

base_dir = File.expand_path(File.dirname(__FILE__))
top_dir = File.expand_path(File.join(base_dir, ".."))
lib_dir = File.join(top_dir, "lib")
test_dir = File.join(top_dir, "test")
$LOAD_PATH.unshift(lib_dir)
$LOAD_PATH.unshift(test_dir)

require "bundler/setup"

require "test/unit"
Test::Unit::Priority.enable

Dir.glob(File.join(test_dir, "**", "test_*.rb")) do |test_file|
  require test_file
end

succeeded = true
target_adapters = [ENV["ACTIVE_LDAP_TEST_ADAPTER"]]
# target_adapters << "ldap"
# target_adapters << "net-ldap"
# target_adapters << "jndi"
target_adapters.each do |adapter|
  ENV["ACTIVE_LDAP_TEST_ADAPTER"] = adapter
  puts "using adapter: #{adapter ? adapter : 'default'}"
  unless Test::Unit::AutoRunner.run(false, nil, ARGV.dup)
    succeeded = false
  end
  puts
end

exit(succeeded)
