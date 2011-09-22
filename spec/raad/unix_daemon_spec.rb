require 'spec_helper'
require 'raad/env'
require 'raad/unix_daemon'
require 'timeout'

class TestService
  include Daemonizable

  attr_accessor :pid_file

  def initialize(pid_file)
    @pid_file = pid_file
  end
end

module Spoon
end unless Raad.jruby?

describe 'UnixDaemon' do

  before :all do
    @l = 'test.log'
    @p = 'test.pid'
    File.delete(@l) if File.exist?(@l)
    File.delete(@p) if File.exist?(@p)
  end

  before :each do
    File.delete(@l) if File.exist?(@l) rescue nil
    File.delete(@p) if File.exist?(@p) rescue nil
    @service = TestService.new(@p)
  end

  describe "non jruby daemonize" do

    it 'should create a pid file' do
      @service.should_receive(:remove_stale_pid_file).once
      @service.daemonize([], 'test') do
        Thread.new{Thread.stop}.join(5)
      end
     
      Timeout.timeout(5) do
        while !File.exist?(@service.pid_file); sleep(0.1); end
        true
      end.should == true

      (pid = @service.pid).should > 0
      Process.kill(:TERM, pid)
    end

    it 'should redirect stdio to a log file' do
      @service.daemonize([], 'test', @l) do
        puts("puts"); STDOUT.flush
        STDERR.puts("STDERR.puts"); STDERR.flush
        STDOUT.puts("STDOUT.puts"); STDOUT.flush
      end

      Timeout.timeout(5) do
        while !File.exist?(@l); sleep(0.1); end
        true
      end.should == true

      f = File.new(@l, "r")
      Timeout.timeout(5) do
        while (l = f.readlines) != ["puts\n", "STDERR.puts\n", "STDOUT.puts\n"]; sleep(0.1); f.rewind; end
        true
      end.should == true
    end
  end unless Raad.jruby?

  describe "jruby daemonize (from any ruby)" do

    # we don't have to use jruby for this test, Spoon is mocked when not jruby.

    it "should swap start for post_fork and call spawnp with args" do
      @service.should_receive(:remove_stale_pid_file).once
      Raad.should_receive(:jruby?).and_return(true)
      Spoon.should_receive(:spawnp).with(Raad.ruby_path, $0, "test", "post_fork")
      @service.daemonize(["test", "start"], 'test')
    end
  end

  describe "jruby daemonize (only in jruby)" do

    it "should daemonize" do
      false.should == false
    end
  end if Raad.jruby?

  describe "post_fork_setup" do

    it 'should create a pid file' do

      STDIN.should_receive(:reopen)
      STDOUT.should_receive(:reopen)
      STDERR.should_receive(:reopen)
      @service.post_fork_setup('test', nil)
      File.exist?(@service.pid_file).should be_true
      @service.pid.should == Process.pid
    end

    it 'should redirect stdio to a log file' do
      @service = TestService.new(@p)

      STDIN.should_receive(:reopen).with("/dev/null")
      STDOUT.should_receive(:reopen).with(@l, 'a')
      STDERR.should_receive(:reopen).with(STDOUT)

      @service.post_fork_setup('test', @l)
    end
  end

  describe 'read/write/remove pid file' do

    it 'should write pid file' do
      @service.write_pid_file
      File.exist?(@service.pid_file).should be_true
      File.read(@p).to_i.should == Process.pid
    end

    it 'should read pid file' do
      @service.write_pid_file
      @service.read_pid_file.should == Process.pid
    end

    it 'should remove pid file' do
      @service.write_pid_file
      File.exist?(@service.pid_file).should be_true
      @service.remove_pid_file
      File.exist?(@service.pid_file).should be_false
    end
  end

  describe 'send_signal' do

    it 'should send signal and terminate process' do
      @service.write_pid_file
      t = Thread.new{Thread.stop}
      Kernel.trap(:USR1) {Thread.new{t.run}}
      Process.should_receive(:running?).once.and_return(false)
      $stdout.should_receive(:write).twice # mute trace
      @service.send_signal(:USR1, 5).should be_true
      Timeout.timeout(5) {t.join}
    end

    it 'should force kill on Timeout::Error exception' do
      @service.write_pid_file
      Process.should_receive(:kill).and_raise(Timeout::Error)
      @service.should_receive(:force_kill_and_remove_pid_file).and_return(true)
      $stdout.should_receive(:write).twice # mute trace
      @service.send_signal(:USR1, 5).should be_true
    end

    it 'should force kill on Interrupt exception' do
      @service.write_pid_file
      Process.should_receive(:kill).and_raise(Interrupt)
      @service.should_receive(:force_kill_and_remove_pid_file).and_return(true)
      $stdout.should_receive(:write).twice # mute trace
      @service.send_signal(:USR1, 5).should be_true
    end

    it 'should remove pid file on Errno::ESRCH exception' do
      @service.write_pid_file
      Process.should_receive(:kill).and_raise(Errno::ESRCH)
      $stdout.should_receive(:write).exactly(4).times # mute trace
      @service.should_receive(:remove_pid_file)
      @service.send_signal(:USR1, 5).should be_false
    end
  end

  def force_kill_and_remove_pid_file(pid)
    puts(">> sending KILL signal to process #{pid}")
    Process.kill("KILL", pid)
    remove_pid_file
    true
  rescue Errno::ESRCH # No such process
    puts(">> can't send KILL, no such process #{pid}")
    remove_pid_file
    false
  end

  describe 'force_kill_and_remove_pid_file' do

    it 'should send KILL signal and terminate process' do
      @service.write_pid_file
      Process.should_receive(:kill).with("KILL", 666).once
      $stdout.should_receive(:write).twice # mute trace
      @service.force_kill_and_remove_pid_file(666).should be_true
    end

    it 'should remove pid file on no such process exception' do
      @service.write_pid_file
      $stdout.should_receive(:write).exactly(4).times # mute trace
      Process.should_receive(:kill).with("KILL", 666).once.and_raise(Errno::ESRCH)
      @service.should_receive(:remove_pid_file)
      @service.force_kill_and_remove_pid_file(666).should be_false
    end
  end
end