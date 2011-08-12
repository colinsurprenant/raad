# Copyright (c) 2011 Praized Media Inc.
# Licensed under the Apache License, Version 2.0
# Author: Colin Surprenant (colin.surprenant@needium.com, colin.surprenant@gmail.com, @colinsurprenant, http://github.com/colinsurprenant)

require 'log4r'

module Raad
  module Logger
    
    extend self
    
    # Sets up the logging for the runner
    # @return [Logger] The logger object
    def setup(options = {})
      @log = Log4r::Logger.new('raad')

      log_format = Log4r::PatternFormatter.new(:pattern => "[#{Process.pid}:%l] %d :: %m")
      setup_file_logger(@log, log_format, options[:file]) if options[:file]
      setup_stdout_logger(@log, log_format) if options[:stdout]

      @verbose = !!options[:verbose]

      @log.level = @verbose ? Log4r::DEBUG : Log4r::INFO
      @log
    end

    def level=(l)
      levels = {
        :debug => Log4r::DEBUG,
        :info => Log4r::INFO,
        :warn => Log4r::WARN,
        :error => Log4r::ERROR,
      }
      @log.level = @verbose ? Log4r::DEBUG : levels[l]
    end

    private 
     
    # setup file logging
    #
    # @param log [Logger] The logger to add file logging too
    # @param log_format [Log4r::Formatter] The log format to use
    # @return [Nil]
    def setup_file_logger(log, log_format, file)
      FileUtils.mkdir_p(File.dirname(file))

      @log.add(Log4r::FileOutputter.new('fileOutput', {
        :filename => file,
        :trunc => false,
        :formatter => log_format
      }))
    end

    # setup stdout logging
    #
    # @param log [Logger] The logger to add stdout logging too
    # @param log_format [Log4r::Formatter] The log format to use
    # @return [Nil]
    def setup_stdout_logger(log, log_format)
      @log.add(Log4r::StdoutOutputter.new('console', :formatter => log_format))
    end
    
    def method_missing(sym, *args)
      @log.send(sym, *args)
    end

  end
end