# Copyright (c) 2011 Praized Media Inc.
# Author: Colin Surprenant (colin@needium.com, colin.surprenant@gmail.com)

module Raad
  
  module_function

  VERSION = "0.1.0"

  @env = 'development'

  # Retrieves the current goliath environment
  #
  # @return [String] the current environment
  def env
    @env
  end

  # Sets the current goliath environment
  #
  # @param [String] env the environment string of [dev|prod|test]
  def env=(env)
    case(env)
    when 'dev', 'development' then @env = 'development'
    when 'prod', 'production' then @env = 'production'
    when 'stage', 'staging' then @env = 'stage'
    when 'test' then @env = 'test'
    end
  end

  # Determines if we are in the production environment
  #
  # @return [Boolean] true if current environemnt is production, false otherwise
  def prod?
    @env == 'production'
  end

  # Determines if we are in the development environment
  #
  # @return [Boolean] true if current environemnt is development, false otherwise
  def dev?
    @env == 'development'
  end

  # Determines if we are in the staging environment
  #
  # @return [Boolean] true if current environemnt is satging, false otherwise
  def stage?
    @env == 'stage'
  end

  # Determines if we are in the test environment
  #
  # @return [Boolean] true if current environemnt is test, false otherwise
  def test?
    @env == 'test'
  end
end