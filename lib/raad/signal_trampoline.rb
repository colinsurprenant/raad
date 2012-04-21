require 'thread'

module SignalTrampoline

  module_function

  SIGNALS = {
    :EXIT => 0, :HUP => 1, :INT => 2, :QUIT => 3, :ILL => 4, :TRAP => 5, :IOT => 6, :ABRT => 6, :FPE => 8, :KILL => 9,
    :BUS => 7, :SEGV => 11, :SYS => 31, :PIPE => 13, :ALRM => 14, :TERM => 15, :URG => 23, :STOP => 19, :TSTP => 20, 
    :CONT => 18, :CHLD => 17, :CLD => 17, :TTIN => 21, :TTOU => 22, :IO => 29, :XCPU => 24, :XFSZ => 25, :VTALRM => 26, 
    :PROF => 27, :WINCH => 28, :USR1 => 10, :USR2 => 12, :PWR => 30, :POLL => 29
  }

  @signal_q = Queue.new
  @handlers = {}
  @handler_thread = nil

  # using threads to bounce signal using a thread-safe queue seem the most robust way to handle signals.
  # it minimizes the code in the trap block and reissue the signal and its handling in the normal Ruby
  # flow, within normal threads. 

  def trap(signal, &block)
    raise("unknown signal") unless SIGNALS.has_key?(signal)
    @handler_thread ||= detach_handler_thread
    @handlers[signal] = block
    Kernel.trap(signal) {Thread.new{@signal_q << signal}}
  end

  def detach_handler_thread
    Thread.new do
      Thread.current.abort_on_exception = true
      loop do
        s = @signal_q.pop
        @handlers[s].call if @handlers[s]
      end
    end
  end

end
