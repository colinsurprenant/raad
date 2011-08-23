# include lib path
$:.unshift File.dirname(__FILE__) + '/../lib'

require 'rubygems'
require 'lib/raad'
# require 'ruby-debug'

class Dummy
  
  def initialize
    @options = {}
    @stop = false
  end

  def start
    puts("start in env=#{Raad::env}")
    Raad::Logger.debug('start debug trace')
    Raad::Logger.info('start info trace')
    Raad::Logger.error('start error trace')

    sleep(3)
  end

  def stop
    puts("stop in env=#{Raad::env}")
    Raad::Logger.debug('stop debug trace')
    Raad::Logger.info('stop info trace')
    Raad::Logger.error('stop error trace')
    @stop = true
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
