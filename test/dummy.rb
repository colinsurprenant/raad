# include lib path
$:.unshift File.dirname(__FILE__) + '/../'


require 'lib/raad'
# require 'ruby-debug'

class Dummy
  
  def initialize
  end

  def start
    puts("start in env=#{Raad::env}")
    Raad::Logger.debug('start debug trace')
    Raad::Logger.info('start info trace')
    Raad::Logger.error('start error trace')

    sleep(60)
  end

  def stop
    puts("stop in env=#{Raad::env}")
    Raad::Logger.debug('stop debug trace')
    Raad::Logger.info('stop info trace')
    Raad::Logger.error('stop error trace')
  end

  def init_traps
    trap(:HUP) do
      Raad::Logger.info('** rotate logs')
    end
  end


end
