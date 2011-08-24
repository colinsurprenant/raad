$:.unshift File.dirname(__FILE__) + '/../lib'
require 'rubygems'
require 'raad'

class SimpleDaemon

  def start
    @stopped = false
    while !@stopped
      Raad::Logger.info("simple_daemon running")
      sleep(1)
    end
  end

  def stop
    @stopped = true
    Raad::Logger.info("simple_daemon stopped")
  end

end
