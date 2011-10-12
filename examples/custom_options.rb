$:.unshift File.dirname(__FILE__) + '/../lib'
require 'rubygems'
require 'raad'

class CustomOptions

  def initialize
    Raad.env = :foobar
    Raad::Logger.debug("CustomOptions initialize")
  end

  def start
    Raad::Logger.debug("CustomOptions start")
    while !Raad.stopped?
      Raad::Logger.info("CustomOptions running in #{Raad.env} env, using z=#{Raad.custom_options[:z].inspect}")
      sleep(1)
    end
  end

  def stop
    Raad::Logger.debug("CustomOptions stop")
  end

  # options_parser must be a class method 
  #
  # @param raad_parser [OptionParser] raad options parser to which custom options rules can be added
  # @param parsed_options [Hash] set parsing results into this hash. retrieve it later in your code using Raad.custom_options
  # @return [OptionParser] the modified options parser must be returned
  def self.options_parser(raad_parser, parsed_options)
    parsed_options[:z] = "default"
    raad_parser.separator "custom service options:"
    raad_parser.on('-z', '--zzz VALUE', "add some z") { |v| parsed_options[:z] = v }
    raad_parser
  end

end
