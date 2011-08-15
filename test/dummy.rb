# include lib path
$:.unshift File.dirname(__FILE__) + '/../'


require 'lib/raad'
# require 'ruby-debug'

class Dummy
  
  def initialize
    @options = {}
  end

  def start
    puts("start in env=#{Raad::env}")
    Raad::Logger.debug('start debug trace')
    Raad::Logger.info('start info trace')
    Raad::Logger.error('start error trace')

    Raad::Logger.info("gaga=#{@options[:gaga]}")

    sleep(10)
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

  def options_parser(raad_options)
    raad_options.separator "dummy service options:"

    raad_options.on('-g', '--gaga NAME', "set gaga name") { |val| @options[:gaga] = val }
    raad_options
  end

end
