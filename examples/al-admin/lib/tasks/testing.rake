# -*- ruby -*-

namespace :test do
  Rake::TestTask.new(:all => "db:test:prepare") do |task|
    task.libs << "test"
    task.verbose = false
    task.test_files = Dir.glob("test/{unit,functional,integration}/**/*_test.rb").uniq
  end
  Rake::Task["test:all"].comment = "Run all tests in a test run"
end
