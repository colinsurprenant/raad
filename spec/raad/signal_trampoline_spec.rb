require 'spec_helper'
require 'raad/signal_trampoline'
require 'thread'
require 'timeout'

describe SignalTrampoline do
  it "should trap signal" do
    t = Thread.new{Thread.stop}
    SignalTrampoline.trap(:USR2) {t.run}
    expect(t.alive?).to be_truthy
    Timeout.timeout(5) {sleep(0.1) while !t.stop?} # avoid race condition
    expect(t.stop?).to be_truthy
    Process.kill(:USR2, Process.pid)
    Timeout.timeout(5) {sleep(0.1) while t.alive?} 
    expect(t.alive?).to be_falsy
    expect(t.join(5)).to eq(t)
  end

  it "should raise on bad signal" do
    expect(lambda{SignalTrampoline.trap(:WAGADOUDOU) {}}).to raise_exception(RuntimeError)
  end
end
