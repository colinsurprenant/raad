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
 
  s.rubyforge_project = "raad"
  
  s.files             = Dir.glob("{lib/**/*.rb}") + %w(README.md CHANGELOG.md LICENSE.md)
  s.require_paths     = ['lib']

  # Test dependencies
  s.add_development_dependency "rspec", ["~> 2.8.0"]
  s.add_development_dependency "rake", ["~> 0.9.2"]

  s.add_runtime_dependency "log4r", ["~> 1.1.9"]
end
