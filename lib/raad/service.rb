module Raad

  # The main execution class for Raad. This will execute in the at_exit
  # handler to run the server.
  class Service

    # Set of caller regex's to be skippe when looking for our API file
    CALLERS_TO_IGNORE = [ # :nodoc:
      /\/raad(\/(service))?\.rb$/, # all raad code
      /rubygems\/custom_require\.rb$/,    # rubygems require hacks
      /bundler(\/runtime)?\.rb/,          # bundler require hacks
      /<internal:/                        # internal in ruby >= 1.9.2
    ]

    # @todo add rubinius (and hopefully other VM impls) ignore patterns ...
    CALLERS_TO_IGNORE.concat(RUBY_IGNORE_CALLERS) if defined?(RUBY_IGNORE_CALLERS)

    # Like Kernel#caller but excluding certain magic entries and without
    # line / method information; the resulting array contains filenames only.
    def self.caller_files
      caller_locations.map { |file, line| file }
    end

    # Like caller_files, but containing Arrays rather than strings with the
    # first element being the file, and the second being the line.
    def self.caller_locations
      caller(1).
        map    { |line| line.split(/:(?=\d|in )/)[0,2] }.
        reject { |file, line| CALLERS_TO_IGNORE.any? { |pattern| file =~ pattern } }
    end

    # Find the service_file that was used to execute the service
    #
    # @return [String] The service file
    def self.service_file
      c = caller_files.first
      c = $0 if !c || c.empty?
      c
    end

    # Execute the service
    #
    # @return [Nil]
    def self.run!
      file = File.basename(service_file, '.rb')
      service = Object.module_eval(camel_case(file)).new

      runner = Raad::Runner.new(ARGV, service)
      runner.run
    end

    private

    # Convert a string to camel case
    #
    # @param str [String] The string to convert
    # @return [String] The camel cased string
    def self.camel_case(str)
      return str if str !~ /_/ && str =~ /[A-Z]+.*/

      str.split('_').map { |e| e.capitalize }.join
    end
  end

  at_exit do
    unless defined?($RAAD_NOT_RUN)
      if $!.nil? && $0 == Raad::Service.service_file
        Service.run!
      end
    end
  end
end
