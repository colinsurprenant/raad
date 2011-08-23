# Copyright (c) 2011 Praized Media Inc.
# Author: Colin Surprenant (colin.surprenant@needium.com, colin.surprenant@gmail.com, @colinsurprenant, http://github.com/colinsurprenant)

require 'optparse'
require 'thread'

module Raad
  class Runner
    include Daemonizable

    SECOND = 1
    SOFT_STOP_TIMEOUT = 58 * SECOND
    HARD_STOP_TIMEOUT = 60 * SECOND

    # The pid file for the server
    # @return [String] The file to write the servers pid file into
    attr_accessor :pid_file

    # The application
    # @return [Object] The service to execute
    attr_accessor :service

    # The parsed options
    # @return [Hash] The options parsed by the runner
    attr_reader :options

    # Create a new Runner
    #
    # @param argv [Array] The command line arguments
    # @param service [Object] The service to execute
    def initialize(argv, service)
      options_parser(service).parse!(argv)

      options[:command] = argv[0].to_s.downcase
      unless ['start', 'stop'].include?(options[:command])
        puts(">> start|stop command is required")
        exit!
      end

      @service = service
      @service_name = nil
      @logger_options = nil
      @pid_file = nil
      @service_thread = nil
      @stopped = false
    end

    def run
      # first load config if present
      Configuration.load(options[:config] || File.expand_path("./config/#{default_service_name}.rb"))

      # then set vars which depends on configuration
      @service_name = options[:name] || Configuration.daemon_name || default_service_name
      @logger_options = {
        :file => options.delete(:log_file) || File.expand_path("#{@service_name}.log"),
        :stdout => options.delete(:log_stdout),
        :verbose => options.delete(:verbose),
      }
      @pid_file = options.delete(:pid_file) || "./#{@service_name}.pid"

      # setup logging
      Logger.setup(@logger_options)
      Logger.level = Configuration.log_level if Configuration.log_level

      if options[:command] == 'stop'
        puts(">> Raad service wrapper v#{VERSION} stopping")
        send_signal('TERM', HARD_STOP_TIMEOUT) # if not stopped afer HARD_STOP_TIMEOUT, SIGKILL will be sent
        exit!
      end
      puts(">> Raad service wrapper v#{VERSION} starting")

      Dir.chdir(File.expand_path(File.dirname("./"))) unless Raad.test?

      jruby = (defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby')
      raise("daemonize not supported in JRuby") if options[:daemonize] && jruby
      
      options[:daemonize] ? daemonize(@service_name, options[:redirect]) {run_service} : run_service
    end

    private

    def default_service_name
      service.class.to_s.split('::').last.gsub(/(.)([A-Z])/,'\1_\2').downcase!
    end

    # Create the options parser
    #
    # @return [OptionParser] Creates the options parser for the runner with the default options
    def options_parser(service)
      @options ||= {
        :daemonize => false,
        :verbose => false,
        :log_stdout => false
      }

      @options_parser ||= OptionParser.new do |opts|
        opts.banner = "usage: <service> [options] start|stop"

        opts.separator ""
        opts.separator "raad common options:"
    
        opts.on('-e', '--environment NAME', "Set the execution environment (prod, dev or test) (default: #{Raad.env.to_s})") { |val| Raad.env = val }

        opts.on('-u', '--user USER', "Run as specified user") {|v| @options[:user] = v }
        opts.on('-l', '--log FILE', "Log to file (default: off)") { |file| @options[:log_file] = file }
        opts.on('-s', '--stdout', "Log to stdout (default: #{@options[:log_stdout]})") { |v| @options[:log_stdout] = v }

        opts.on('-c', '--config FILE', "Config file (default: ./config/<service>.rb)") { |v| @options[:config] = v }
        opts.on('-d', '--daemonize', "Run daemonized in the background (default: #{@options[:daemonize]})") { |v| @options[:daemonize] = v }
        opts.on('-P', '--pid FILE', "Pid file (default: off)") { |file| @options[:pid_file] = file }
        opts.on('-r', '--redirect FILE', "Redirect stdout to FILE when daemonized") { |v| @options[:redirect] = v }
        opts.on('-n', '--name NAME', "Daemon process name") { |v| @options[:name] = v }
        opts.on('-v', '--verbose', "Enable verbose logging (default: #{@options[:verbose]})") { |v| @options[:verbose] = v }

        opts.on('-h', '--help', 'Display help message') { show_options(opts) }
      end
      service.respond_to?(:options_parser) ? service.options_parser(@options_parser) : @options_parser
    end

    # Output the servers options
    #
    # @param opts [OptionsParser] The options parser
    # @return [exit] This will exit Ruby
    def show_options(opts)
      puts(opts)
      exit!
    end

    # Run the server
    #
    # @return [Nil]
    def run_service
      Logger.info("starting #{@service_name} service in #{Raad.env.to_s} mode")

      at_exit do
        Logger.info(">> Raad service wrapper stopped")
      end

      # by default exit on SIGTERM and SIGINT
      [:INT, :TERM, :QUIT].each do |sig|
        trap(sig) {stop_service}
      end

      service.init_traps if service.respond_to?(:init_traps)

      @service_thread = Thread.new do
        Thread.current.abort_on_exception = true
        service.start
      end
      while @service_thread.join(SECOND).nil?
        if @stopped
          Logger.info("stopping service")
          service.stop if service.respond_to?(:stop)
          wait_or_kill_service
          return
        end
      end

      unless @stopped
        Logger.info("stopping service")
        service.stop if service.respond_to?(:stop)
      end
    end

    def stop_service
      @stopped = true
    end

    def wait_or_kill_service
      try = 0; join = nil
      while (try += 1) <= SOFT_STOP_TIMEOUT && join.nil? do
        join = @service_thread.join(SECOND)
        Logger.debug("waiting for service to stop #{try}/#{SOFT_STOP_TIMEOUT}") if join.nil?
      end
      if join.nil?
        Logger.error("stop timeout exhausted, killing service thread")
        @service_thread.kill
        @service_thread.join
      end
    end
     
  end
end
