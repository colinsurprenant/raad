$:.unshift File.dirname(__FILE__) + '/../lib'
require 'rubygems'
require 'raad'

class SimpleDaemon

  def start
    while !Raad.stopped?
      Raad::Logger.info("simple_daemon running")
      sleep(1)
    end
  end

  def stop
    Raad::Logger.info("simple_daemon stopped")
  end

end
