require 'rbconfig'

module Raad
  
  @env = :development

  # retrieves the current environment
  #
  # @return [Symbol] the current environment
  def env
    @env
  end

  # sets the current environment
  #
  # @param [String or Symbol] env the environment
  def env=(env)
    case(env.to_s)
    when 'dev', 'development' then @env = :development
    when 'prod', 'production' then @env = :production
    when 'stage', 'staging' then @env = :stage
    when 'test' then @env = :test
    else @env = env.to_sym
    end
  end

  # Determines if we are in the production environment
  #
  # @return [Boolean] true if current environemnt is production, false otherwise
  def production?
    @env == :production
  end

  # are we in the development environment
  #
  # @return [Boolean] true if current environemnt is development, false otherwise
  def development?
    @env == :development
  end

  # are we in the staging environment
  #
  # @return [Boolean] true if current environemnt is staging, false otherwise
  def stage?
    @env == :stage
  end

  # are we in the test environment
  #
  # @return [Boolean] true if current environemnt is test, false otherwise
  def test?
    @env == :test
  end

  # are we running inside jruby
  #
  # @return [Boolean] true if runnig inside jruby
  def jruby?
    defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
  end

  # absolute path of current interpreter
  #
  # @return [String] absolute path of current interpreter
  def ruby_path
    File.join(Config::CONFIG["bindir"], Config::CONFIG["RUBY_INSTALL_NAME"] + Config::CONFIG["EXEEXT"])
  end

  module_function :env, :env=, :production?, :development?, :stage?, :test?, :jruby?, :ruby_path

end