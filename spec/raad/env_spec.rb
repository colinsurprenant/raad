require 'spec_helper'
require 'raad/env'

describe "Raad env" do

  it "should set default env to :development" do
    expect(Raad.env).to eq(:development)
    expect(Raad.development?).to be_truthy
  end

  it "should set development env" do
    [:development, :dev, "development", "dev"].each do |env|
      Raad.env = env
      expect(Raad.env).to eq(:development)
      expect(Raad.development?).to be_truthy
      [:production?, :stage?, :test?].each do |env|
        expect(Raad.send(env)).to be_falsy
      end
    end
  end

  it "should set production env" do
    [:production, :prod, "production", "prod"].each do |env|
      Raad.env = env
      expect(Raad.env).to eq(:production)
      expect(Raad.production?).to be_truthy
      [:development?, :stage?, :test?].each do |env|
        expect(Raad.send(env)).to be_falsy
      end
    end
  end

  it "should set stage env" do
    [:stage, :staging, "stage", "staging"].each do |env|
      Raad.env = env
      expect(Raad.env).to eq(:stage)
      expect(Raad.stage?).to be_truthy
      [:development?, :production?, :test?].each do |env|
        expect(Raad.send(env)).to be_falsy
      end
    end
  end

  it "should set test env" do
    [:test, "test"].each do |env|
      Raad.env = env
      expect(Raad.env).to eq(:test)
      expect(Raad.test?).to be_truthy
      [:development?, :production?, :stage?].each do |env|
        expect(Raad.send(env)).to be_falsy
      end
    end
  end

  it "should set arbritary env" do
    [:arbritary, "arbritary"].each do |env|
      Raad.env = env
      expect(Raad.env).to eq(:arbritary)
      [:development?, :production?, :stage?, :test?].each do |env|
        expect(Raad.send(env)).to be_falsy
      end
    end
  end

  it "should test for jruby" do
    expect([true, false]).to include(Raad.jruby?)
  end

  it "should report ruby path" do
    expect(File.exist?(Raad.ruby_path)).to be_truthy
  end

  it "should default to empty ruby_options" do
    expect(Raad.ruby_options.length).to eq(0)
  end

  it "should set ruby_options" do
    Raad.ruby_options = "a b"
    expect(Raad.ruby_options).to eq(['a', 'b'])
  end
end
