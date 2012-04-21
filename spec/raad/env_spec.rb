require 'spec_helper'
require 'raad/env'

describe "Raad env" do

  it "should set default env to :development" do
    Raad.env.should == :development
    Raad.development?.should be_true
  end

  it "should set development env" do
    [:development, :dev, "development", "dev"].each do |env|
      Raad.env = env
      Raad.env.should == :development
      Raad.development?.should be_true
      [:production?, :stage?, :test?].each{|env| Raad.send(env).should be_false}
    end
  end

  it "should set production env" do
    [:production, :prod, "production", "prod"].each do |env|
      Raad.env = env
      Raad.env.should == :production
      Raad.production?.should be_true
      [:development?, :stage?, :test?].each{|env| Raad.send(env).should be_false}
    end
  end

  it "should set stage env" do
    [:stage, :staging, "stage", "staging"].each do |env|
      Raad.env = env
      Raad.env.should == :stage
      Raad.stage?.should be_true
      [:development?, :production?, :test?].each{|env| Raad.send(env).should be_false}
    end
  end

  it "should set test env" do
    [:test, "test"].each do |env|
      Raad.env = env
      Raad.env.should == :test
      Raad.test?.should be_true
      [:development?, :production?, :stage?].each{|env| Raad.send(env).should be_false}
    end
  end

  it "should set arbritary env" do
    [:arbritary, "arbritary"].each do |env|
      Raad.env = env
      Raad.env.should == :arbritary
      [:development?, :production?, :stage?, :test?].each{|env| Raad.send(env).should be_false}
    end
  end

  it "should test for jruby" do
    [true, false].should include(Raad.jruby?)
  end

  it "should report ruby path" do
    File.exist?(Raad.ruby_path).should be_true
  end

  it "should default to empty ruby_options" do
    Raad.ruby_options.should == []
  end

  it "should set ruby_options" do
    Raad.ruby_options = "a b"
    Raad.ruby_options.should == ['a', 'b']
  end
end
