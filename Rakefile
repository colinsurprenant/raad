require 'rake'
require "rubygems"

begin
  require 'rspec/core/rake_task'
  desc "Run the specs under spec/"
  RSpec::Core::RakeTask.new
rescue NameError, LoadError => e
  puts e
end
