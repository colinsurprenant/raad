require 'rake'
require "rubygems"

task :default => :spec

begin
  require 'rspec/core/rake_task'
  desc "run specs in the current ruby env"
  task :spec do
    sh "ruby -v"
    RSpec::Core::RakeTask.new
  end
rescue NameError, LoadError => e
  puts e
end

desc "run specs for all rubies"
task :specs do
  sh "spec/spec_all.sh"
end

desc "run validations in the current ruby env"
task :validation  do
  sh "test/validate.sh"
end

desc "run validations for all rubies"
task :validations  do
  sh "test/validate_all.sh"
end

desc "install all tested rubies under rvm"
task :rvm_setup do
  sh "test/rvm_setup.sh"
end
