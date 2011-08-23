# Copyright (c) 2011 Praized Media Inc.
# Author: Colin Surprenant (colin.surprenant@needium.com, colin.surprenant@gmail.com, @colinsurprenant, http://github.com/colinsurprenant)

module Raad
  
  @env = :development

  # Retrieves the current environment
  #
  # @return [Symbol] the current environment
  def env
    @env
  end

  # Sets the current environment
  #
  # @param [String or Symbol] env the environment [development|production|stage|test]
  def env=(env)
    case(env.to_s)
    when 'dev', 'development' then @env = :development
    when 'prod', 'production' then @env = :production
    when 'stage', 'staging' then @env = :stage
    when 'test' then @env = :test
    end
  end

  # Determines if we are in the production environment
  #
  # @return [Boolean] true if current environemnt is production, false otherwise
  def production?
    @env == :production
  end

  # Determines if we are in the development environment
  #
  # @return [Boolean] true if current environemnt is development, false otherwise
  def development?
    @env == :development
  end

  # Determines if we are in the staging environment
  #
  # @return [Boolean] true if current environemnt is staging, false otherwise
  def stage?
    @env == :stage
  end

  # Determines if we are in the test environment
  #
  # @return [Boolean] true if current environemnt is test, false otherwise
  def test?
    @env == :test
  end

  module_function :env, :env=, :production?, :development?, :stage?, :test?

end