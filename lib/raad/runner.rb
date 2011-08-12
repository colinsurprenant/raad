# Copyright (c) 2011 Praized Media Inc.
# Author: Colin Surprenant (colin@needium.com, colin.surprenant@gmail.com)

require 'optparse'

require 'lib/raad/logger'

module Raad
  # The Goliath::Runner is responsible for parsing any provided options, settting up the
  # rack application, creating a logger, and then executing the Goliath::Server with the loaded information.
  class Runner

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
      options_parser.parse!(argv)

      @service = service
      
      @logger_options = {
        :file => options.delete(:log_file),
        :stdout => options.delete(:log_stdout),
        :verbose => options.delete(:verbose),
      }

      @pid_file = options.delete(:pid_file)
      @daemonize = options.delete(:daemonize)

      @service_options = options
    end

    # Create the options parser
    #
    # @return [OptionParser] Creates the options parser for the runner with the default options
    def options_parser
      @options ||= {
        :daemonize => false,
        :verbose => false,
        :log_stdout => false
      }

      @options_parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: <service> [options]"

        opts.separator ""
        opts.separator "service options:"

        opts.on('-e', '--environment NAME', "Set the execution environment (prod, dev or test) (default: #{Raad.env})") { |val| Raad.env = val }

        opts.on('-u', '--user USER', "Run as specified user") {|v| @options[:user] = v }
        opts.on('-l', '--log FILE', "Log to file (default: off)") { |file| @options[:log_file] = file }
        opts.on('-s', '--stdout', "Log to stdout (default: #{@options[:log_stdout]})") { |v| @options[:log_stdout] = v }

        opts.on('-c', '--config FILE', "Config file (default: ./config/<service>.rb)") { |v| @options[:config] = v }
        opts.on('-P', '--pid FILE', "Pid file (default: off)") { |file| @options[:pid_file] = file }
        opts.on('-d', '--daemonize', "Run daemonized in the background (default: #{@options[:daemonize]})") { |v| @options[:daemonize] = v }
        opts.on('-v', '--verbose', "Enable verbose logging (default: #{@options[:verbose]})") { |v| @options[:verbose] = v }

        opts.on('-h', '--help', 'Display help message') { show_options(opts) }
      end
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
      puts(opts)
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

      Logger.info("starting #{$0} service in #{Raad.env} mode")

      at_exit do
        Logger.info(">> Raad service wrapper stopped")
      end
      at_exit { stop_service }

      # by default exit on SIGTERM and SIGINT
      [:INT, :TERM].each do |sig|
        trap(sig) { exit }
      end

      service.init_traps if service.respond_to?(:init_traps)

      service.start
    end

    def stop_service
      Logger.info("stopping service")
      service.stop if service.respond_to?(:stop)
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
