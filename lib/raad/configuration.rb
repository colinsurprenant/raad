module Raad
  module Configuration
    extend self

    def self.init(&block)
      instance_eval(&block) 
    end

    def [](key)
      config[key]
    end

    # Loads a configuration file and eval its content in the service object context
    #
    # @param file [String] The file to load, if not set will use ./config/{servive_name}
    # @return [Nil]
    def load(file = nil)
      return unless File.exists?(file)
      self.instance_eval(IO.read(file))
    end

    private

    # cosmetic alias for config dsl
    def configuration(&block)
      Configuration.init(&block)
    end

    def set(key, value)
      config[key] = value
    end

    def config
      @config ||= Hash.new
    end

    def method_missing(sym, *args)
      if sym.to_s =~ /(.+)=$/
        config[$1] = args.first
      else
        config[sym]
      end
    end

  end
end
