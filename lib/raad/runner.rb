require 'optparse'
require 'thread'
require 'monitor'

module Raad
  class Runner
    include Daemonizable

    SECOND = 1
    SOFT_STOP_TIMEOUT = 58 * SECOND
    HARD_STOP_TIMEOUT = 60 * SECOND

    attr_accessor :service, :pid_file, :options

    # Create a new Runner
    #
    # @param argv [Array] command line arguments
    # @param service [Object] service to execute
    def initialize(argv, service)
      create_options_parser(service).parse!(argv)

      # start/stop 
      @options[:command] = argv[0].to_s.downcase
      unless ['start', 'stop'].include?(options[:command])
        puts(">> start|stop command is required")
        exit!(false)
      end

      @service = service
      @service_name = nil
      @logger_options = nil
      @pid_file = nil

      # signals handling
      @signals = []
      @monitor = Monitor.new
      @stop_signaled = false
    end

    def run
      # first load config if present
      Configuration.load(options[:config] || File.expand_path("./config/#{default_service_name}.rb"))

      # settings which depends on configuration
      @service_name = options[:name] || Configuration.daemon_name || default_service_name

      unless options[:log_file]
        options[:log_file] = (options[:daemonize] ? File.expand_path("#{@service_name}.log") : nil)
      end
      unless options[:log_stdout]
        options[:log_stdout] = !options[:daemonize]
      end
      @logger_options = {
        :file => options.delete(:log_file),
        :stdout => options.delete(:log_stdout),
        :verbose => options.delete(:verbose),
      }
      @pid_file = options.delete(:pid_file) || "./#{@service_name}.pid"

      # check for stop command, @pid_file must be set
      if options[:command] == 'stop'
        puts(">> Raad service wrapper v#{VERSION} stopping")
        success = send_signal('TERM', HARD_STOP_TIMEOUT) # if not stopped afer HARD_STOP_TIMEOUT, SIGKILL will be sent
        exit!(success)
      end

      # setup logging
      Logger.setup(@logger_options)
      Logger.level = Configuration.log_level if Configuration.log_level

      puts(">> Raad service wrapper v#{VERSION} starting")

      Dir.chdir(File.expand_path(File.dirname("./"))) unless Raad.test?

      jruby = (defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby')
      raise("daemonize not supported in JRuby") if options[:daemonize] && jruby
      
      options[:daemonize] ? daemonize(@service_name, options[:redirect]) {run_service} : run_service
    end

    private

    # Run the service
    #
    # @return [Nil]
    def run_service
      Logger.info("starting #{@service_name} service in #{Raad.env.to_s} mode")

      at_exit do
        Logger.info(">> Raad service wrapper stopped")
      end

      # store received signals into the @signal queue
      [:INT, :TERM, :QUIT].each do |sig|
        trap(sig) {@monitor.synchronize{@signals << :STOP}}
      end

      # launch the signal handler thread
      signals_thread = Thread.new do
        Thread.current.abort_on_exception = true
        loop do
          signals = @monitor.synchronize{s = @signals.dup; @signals.clear; s}

          if signals.include?(:STOP) && !@stop_signaled
            @stop_signaled = true
            stop_service
          end

          sleep(0.5)
        end
      end

      # launch the service thread and call start. we expect start not to return
      # unless it is done or has been stopped.
      service_thread = Thread.new do
        Thread.current.abort_on_exception = true
        service.start
        stop_service unless @stop_signaled
      end

      success = wait_or_kill(service_thread)
      success ? exit : exit!(false)
    end

    def stop_service
      Logger.info("stopping #{@service_name} service")
      service.stop if service.respond_to?(:stop)
    end

    # try to do a timeout join periodically on the given thread. if the join succeed then the stop
    # sequence was successful and return true.
    # Otherwise, on timeout if stop has beed signaled, wait a maximum of SOFT_STOP_TIMEOUT on the
    # thread and kill it if the timeout is reached and return false in that case.
    def wait_or_kill(thread)
      while thread.join(SECOND).nil?
        if @stop_signaled
          try = 0; join = nil
          while (try += 1) <= SOFT_STOP_TIMEOUT && join.nil? do
            join = thread.join(SECOND)
            Logger.debug("waiting for service to stop #{try}/#{SOFT_STOP_TIMEOUT}") if join.nil?
          end
          if join.nil?
            Logger.error("stop timeout exhausted, killing service thread")
            thread.kill
            return false
          end
          return true
        end
      end
      true
    end

    def default_service_name
      service.class.to_s.split('::').last.gsub(/(.)([A-Z])/,'\1_\2').downcase!
    end

    # Create the options parser
    #
    # @return [OptionParser] Creates the options parser for the runner with the default options
    def create_options_parser(service)
      @options ||= {
        :daemonize => false,
        :verbose => false,
      }

      options_parser ||= OptionParser.new do |opts|
        opts.banner = "usage: ruby <service>.rb [options] start|stop"

        opts.separator ""
        opts.separator "Raad common options:"
    
        opts.on('-e', '--environment NAME', "set the execution environment (default: #{Raad.env.to_s})") { |val| Raad.env = val }

        opts.on('-l', '--log FILE', "log to file (default: in console mode: no, daemonized: <service>.log)") { |file| @options[:log_file] = file }
        opts.on('-s', '--stdout', "log to stdout (default: in console mode: true, daemonized: false)") { |v| @options[:log_stdout] = v }

        opts.on('-c', '--config FILE', "config file (default: ./config/<service>.rb)") { |v| @options[:config] = v }
        opts.on('-d', '--daemonize', "run daemonized in the background (default: #{@options[:daemonize]})") { |v| @options[:daemonize] = v }
        opts.on('-P', '--pid FILE', "pid file when daemonized (default: <service>.pid)") { |file| @options[:pid_file] = file }
        opts.on('-r', '--redirect FILE', "redirect stdout to FILE when daemonized (default: no)") { |v| @options[:redirect] = v }
        opts.on('-n', '--name NAME', "daemon process name (default: <service>)") { |v| @options[:name] = v }
        opts.on('-v', '--verbose', "enable verbose logging (default: #{@options[:verbose]})") { |v| @options[:verbose] = v }

        opts.on('-h', '--help', 'display help message') { show_options(opts) }
      end
      service.respond_to?(:options_parser) ? service.options_parser(options_parser) : options_parser
    end

    # Output the servers options
    #
    # @param opts [OptionsParser] The options parser
    # @return [exit] This will exit Ruby
    def show_options(opts)
      puts(opts)
      exit!(false)
    end
     
  end
end
