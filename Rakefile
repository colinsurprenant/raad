require 'rake'
require "rubygems"

task :default => :spec

begin
  require 'rspec/core/rake_task'
  desc "run the specs under spec/"
  task :spec do
    sh "ruby -v"
    RSpec::Core::RakeTask.new
  end
rescue NameError, LoadError => e
  puts e
end

desc "run all validations for all rubies"
task :validations  do
  sh "test/validate_all.sh"
end

desc "run all specs for all rubies"
task :specs do
  sh "spec/spec_all.sh"
end