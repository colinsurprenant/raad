$:.unshift File.dirname(__FILE__) + '/../../lib'
require 'rubygems'
require 'raad'

class Test1

  # typical, well behaved stoppable service

  def start
    @stopped = false
    sleep(3)
    Raad::Logger.info("test1 running")
    sleep(0.1) while !@stopped
  end

  def stop
    Raad::Logger.info("test1 stop called")
    @stopped = true
  end

end
