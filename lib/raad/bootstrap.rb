module Raad

  # The bootstrap class for Raad. This will execute in the at_exit
  # handler to run the service.
  class Bootstrap

    CALLERS_TO_IGNORE = [ # :nodoc:
      /\/raad(\/(bootstrap))?\.rb$/,    # all raad code
      /rubygems\/custom_require\.rb$/,  # rubygems require hacks
      /bundler(\/runtime)?\.rb/,        # bundler require hacks
      /<internal:/                      # internal in ruby >= 1.9.2
    ]

    CALLERS_TO_IGNORE.concat(RUBY_IGNORE_CALLERS) if defined?(RUBY_IGNORE_CALLERS)

    # Like Kernel#caller but excluding certain magic entries and without
    # line / method information; the resulting array contains filenames only.
    def self.caller_files
      caller_locations.map { |file, line| file }
    end

    # like caller_files, but containing Arrays rather than strings with the
    # first element being the file, and the second being the line.
    def self.caller_locations
      caller(1).
        map    { |line| line.split(/:(?=\d|in )/)[0,2] }.
        reject { |file, line| CALLERS_TO_IGNORE.any? { |pattern| file =~ pattern } }
    end

    # find the service_file that was used to execute the service
    #
    # @return [String] The service file
    def self.service_file
      c = caller_files.first
      c = $0 if !c || c.empty?
      c
    end

    # execute the service
    #
    # @return [Nil]
    def self.run!
      service_class = Object.module_eval(camel_case(File.basename(service_file, '.rb')))
      Runner.new(ARGV, service_class).run
    end

    private

    # convert a string to camel case
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
      if $!.nil? && $0 == Raad::Bootstrap.service_file
        Raad::Bootstrap.run!
      end
    end
  end
end
