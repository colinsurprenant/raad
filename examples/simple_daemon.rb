$:.unshift File.dirname(__FILE__) + '/../lib'
require 'rubygems'
require 'raad'

class SimpleDaemon

  def start
    Raad::Logger.debug("SimpleDaemon start")
    while !Raad.stopped?
      Raad::Logger.info("SimpleDaemon running")
      sleep(1)
    end
  end

  def stop
    Raad::Logger.debug("SimpleDaemon stop")
  end

end
