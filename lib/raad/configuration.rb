# Copyright (c) 2011 Praized Media Inc.
# Author: Colin Surprenant (colin.surprenant@needium.com, colin.surprenant@gmail.com, @colinsurprenant, http://github.com/colinsurprenant)

module Raad
  module Configuration
    extend self

    def self.init(&block)
      instance_eval(&block) 
    end

    def [](key)
      config[key]
    end

    private

    def set(key, value)
      config[key] = value
    end

    def config
      @config ||= Hash.new
    end

    def method_missing(sym, *args)
      if sym.to_s =~ /(.+)=$/
        config[$1] = args.first
      else
        config[sym]
      end
    end

  end
end
