# Copyright (c) 2011 Praized Media Inc.
# Author: Colin Surprenant (colin.surprenant@needium.com, colin.surprenant@gmail.com, @colinsurprenant, http://github.com/colinsurprenant)

module Raad
  Root = File.dirname(__FILE__)
  $:.unshift Root
end

require 'rubygems'
require 'lib/raad/version'
require 'lib/raad/raad'
require 'lib/raad/configuration'
require 'lib/raad/runner'
require 'lib/raad/application'
require 'lib/raad/logger'
