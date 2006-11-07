#!/usr/bin/env ruby

require 'yaml'
require "test/unit"

base_dir = File.expand_path(File.dirname(__FILE__))
top_dir = File.expand_path(File.join(base_dir, ".."))
$LOAD_PATH.unshift(File.join(top_dir, "lib"))
$LOAD_PATH.unshift(File.join(top_dir, "test"))

require 'test-unit-ext'

if Test::Unit::AutoRunner.respond_to?(:standalone?)
  exit Test::Unit::AutoRunner.run($0, File.dirname($0))
else
  exit Test::Unit::AutoRunner.run(false, File.dirname($0))
end
