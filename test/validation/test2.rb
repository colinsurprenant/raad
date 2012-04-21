$:.unshift File.dirname(__FILE__) + '/../../lib'
require 'rubygems'
require 'raad'

class Test2

  # hanging service

  def start
    Raad::Logger.info("test2 running")
    Thread.stop
  end

  def stop
    Raad::Logger.info("test2 stop called")
  end

end
