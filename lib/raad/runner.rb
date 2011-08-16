# Copyright (c) 2011 Praized Media Inc.
# Author: Colin Surprenant (colin.surprenant@needium.com, colin.surprenant@gmail.com, @colinsurprenant, http://github.com/colinsurprenant)

require 'optparse'
require 'thread'

module Raad
  # The Goliath::Runner is responsible for parsing any provided options, settting up the
  # rack application, creating a logger, and then executing the Goliath::Server with the loaded information.
  class Runner

    SECOND = 1
    STOP_TIMEOUT = 30 * SECOND

    # Flag to determine if the server should daemonize
    # @return [Boolean] True if the server should daemonize, false otherwise
    attr_accessor :daemonize

    # The pid file for the server
    # @return [String] The file to write the servers pid file into
    attr_accessor :pid_file

    # The  application
    # @return [Object] The rack application the server will execute
    attr_accessor :service

    # The parsed options
    # @return [Hash] The options parsed by the runner
    attr_reader :options

    # Create a new Goliath::Runner
    #
    # @param argv [Array] The command line arguments
    # @param api [Object | nil] The Goliath::API this runner is for, can be nil
    # @return [Goliath::Runner] An initialized Goliath::Runner
    def initialize(argv, service)
      options_parser(service).parse!(argv)

      @service = service
      
      @logger_options = {
        :file => options.delete(:log_file),
        :stdout => options.delete(:log_stdout),
        :verbose => options.delete(:verbose),
      }

      @pid_file = options.delete(:pid_file)
      @daemonize = options.delete(:daemonize)

      @service_options = options

      @service_thread = nil
      @stop_lock = Mutex.new
      @stopped = false
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
        opts.banner = "Usage: <service> [options]"

        opts.separator ""
        opts.separator "raad common options:"

        opts.on('-e', '--environment NAME', "Set the execution environment (prod, dev or test) (default: #{Raad.env.to_s})") { |val| Raad.env = val }

        opts.on('-u', '--user USER', "Run as specified user") {|v| @options[:user] = v }
        opts.on('-l', '--log FILE', "Log to file (default: off)") { |file| @options[:log_file] = file }
        opts.on('-s', '--stdout', "Log to stdout (default: #{@options[:log_stdout]})") { |v| @options[:log_stdout] = v }

        opts.on('-c', '--config FILE', "Config file (default: ./config/<service>.rb)") { |v| @options[:config] = v }
        opts.on('-P', '--pid FILE', "Pid file (default: off)") { |file| @options[:pid_file] = file }
        opts.on('-d', '--daemonize', "Run daemonized in the background (default: #{@options[:daemonize]})") { |v| @options[:daemonize] = v }
        opts.on('-v', '--verbose', "Enable verbose logging (default: #{@options[:verbose]})") { |v| @options[:verbose] = v }

        opts.on('-h', '--help', 'Display help message') { show_options(opts) }
      end
      service.respond_to?(:options_parser) ? service.options_parser(@options_parser) : @options_parser
    end

    # Create environment to run the server.
    # If daemonize is set this will fork off a child and kill the runner.
    #
    # @return [Nil]
    def run
      Dir.chdir(File.expand_path(File.dirname("./"))) unless Raad.test?

      jruby = (defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby')
      raise("daemonize not supported in JRuby") if @daemonize && jruby
      
      if @daemonize
        Process.fork do
          Process.setsid
          exit if fork

          @pid_file ||= './raad.pid'
          @logger_options[:file] ||= File.expand_path('raad.log')
          store_pid(Process.pid)

          File.umask(0000)

          stdout_log_file = "#{File.dirname(@logger_options[:file])}/#{File.basename(@logger_options[:file])}_stdout.log"

          STDIN.reopen("/dev/null")
          STDOUT.reopen(stdout_log_file, "a")
          STDERR.reopen(STDOUT)

          run_service
        end
      else
        run_service
      end
    end

    private

    # Output the servers options
    #
    # @param opts [OptionsParser] The options parser
    # @return [exit] This will exit Ruby
    def show_options(opts)
      exit!
    end

    # Run the server
    #
    # @return [Nil]
    def run_service
      Logger.setup(@logger_options)

      load_config(options[:config])
      Logger.level = Configuration.log_level if Configuration.log_level

      # set process name
      $0 = Configuration.daemon_name if Configuration.daemon_name

      Logger.info("starting #{$0} service in #{Raad.env.to_s} mode")

      at_exit do
        stop_service
        Logger.info(">> Raad service wrapper stopped")
      end

      # by default exit on SIGTERM and SIGINT
      [:INT, :TERM].each do |sig|
        trap(sig) { stop_service }
      end

      service.init_traps if service.respond_to?(:init_traps)

      @service_thread = Thread.new do
        Thread.current.abort_on_exception = true
        service.start
      end
      @service_thread.join
    end

    def stop_service
      @stop_lock.synchronize do
        unless @stopped 
          @stopped = true
          Logger.info("stopping service")
          service.stop if service.respond_to?(:stop)

          
          join = nil; try = 0
          while try <= STOP_TIMEOUT && join.nil? do
            try += 1
            join = @service_thread.join(SECOND)
            Logger.warn("waiting for service to stop") if join.nil?
          end
          if join.nil?
            Logger.error("stop timeout exhausted, killing service")
            @service_thread.kill
          end
        end
      end
    end

    # Store the services pid into the @pid_file
    #
    # @param pid [Integer] The pid to store
    # @return [Nil]
    def store_pid(pid)
      FileUtils.mkdir_p(File.dirname(@pid_file))
      File.open(@pid_file, 'w') { |f| f.write(pid) }
    end     
     
    # Loads a configuration file and eval its content in the service object context
    #
    # @param file [String] The file to load, if not set will use ./config/{servive_name}
    # @return [Nil]
    def load_config(file = nil)
      service_name = service.class.to_s.split('::').last.gsub(/(.)([A-Z])/,'\1_\2').downcase!
      file ||= File.expand_path("./config/#{service_name}.rb")
      unless File.exists?(file)
        Logger.warn("no config file=#{file}")
        return
      end
      self.instance_eval(IO.read(file))
    end

    # cosmetic alias for config dsl
    def configuration(&block)
      Configuration.init(&block)
    end

  end
end
