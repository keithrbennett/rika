require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc 'Download jars'
task :download_jars do
	system "mvn dependency:copy-dependencies"
 end