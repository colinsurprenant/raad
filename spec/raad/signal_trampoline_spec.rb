require 'spec_helper'
require 'raad/signal_trampoline'
require 'thread'
require 'timeout'

describe SignalTrampoline do
  it "should trap signal" do
    t = Thread.new{Thread.stop}
    SignalTrampoline.trap(:USR1) {t.run}
    t.alive?.should be_true
    Timeout.timeout(5) {sleep(0.1) while !t.stop?} # avoid race condition
    t.stop?.should be_true
    Process.kill(:USR1, Process.pid)
    Timeout.timeout(5) {sleep(0.1) while t.alive?} 
    t.alive?.should be_false
    t.join(5).should == t
  end

  it "should raise on bad signal" do
    lambda{SignalTrampoline.trap(:WAGADOUDOU) {}}.should raise_exception
  end
end
