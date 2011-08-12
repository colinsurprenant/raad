# Copyright (c) 2011 Praized Media Inc.
# Author: Colin Surprenant (colin@needium.com, colin.surprenant@gmail.com)

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require 'raad/version'

Gem::Specification.new do |s|  
  s.name        = "raad"
  s.version     = Raad::VERSION
  s.authors     = ["Colin Surprenant"]
  s.email       = ["colin.surprenant@gmail.com"]
  s.homepage    = "http://github.com/praized/raad"
  s.summary     = "Ruby as a Daemon"
  s.description = "Ruby as a Daemon lightweight service wrapper"
 
  s.required_rubygems_version = ">= 1.3.0"
  s.rubyforge_project = "raad"
  
  s.files             = Dir.glob("{lib/**/*.rb}") + %w(README.md CHANGELOG.md LICENCE.md)
  s.require_path      = 'lib'

  s.add_development_dependency "rubyforge"

  # Test dependencies
  s.add_development_dependency "rspec", ["~> 2.5.0"]

  s.add_runtime_dependency "log4r", ["~> 1.1.9"]
end
 
