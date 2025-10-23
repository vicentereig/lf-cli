require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Run RSpec tests"
task :test => :spec

desc "Run console with gem loaded"
task :console do
  require "irb"
  require "langfuse_cli"
  ARGV.clear
  IRB.start
end
