require 'spec_helper'
require 'raad/signal_trampoline'
require 'thread'

describe SignalTrampoline do
  it "should trap signal" do
    t = Thread.new{Thread.stop}
    SignalTrampoline.trap(:USR1) {t.run}
    t.alive?.should == true
    t.stop?.should == true
    Process.kill(:USR1, Process.pid)
    t.join(2).should == t
    t.alive?.should == false
  end

  it "should raise on bad signal" do
    lambda{SignalTrampoline.trap(:WAGADOUDOU) {}}.should raise_exception
  end
end
