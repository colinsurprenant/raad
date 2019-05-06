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
      expect(@service).to receive(:remove_stale_pid_file).once
      @service.daemonize([], 'test') do
        Thread.new{Thread.stop}.join(5)
      end
     
      expect(Timeout.timeout(5) do
        while !File.exist?(@service.pid_file); sleep(0.1); end
        true
      end).to be_truthy

      expect(pid = @service.pid).to be_gt(0)
      Process.kill(:TERM, pid)
    end

    it 'should redirect stdio to a log file' do
      @service.daemonize([], 'test', @l) do
        puts("puts"); STDOUT.flush
        STDERR.puts("STDERR.puts"); STDERR.flush
        STDOUT.puts("STDOUT.puts"); STDOUT.flush
      end

      expect(Timeout.timeout(5) do
        while !File.exist?(@l); sleep(0.1); end
        true
      end).to be_truthy

      f = File.new(@l, "r")
      expect(Timeout.timeout(5) do
        while (l = f.readlines) != ["puts\n", "STDERR.puts\n", "STDOUT.puts\n"]; sleep(0.1); f.rewind; end
        true
      end).to be_truthy
    end
  end unless Raad.jruby?

  describe "jruby daemonize (from any ruby)" do

    # we don't have to use jruby for this test, Spoon is mocked when not jruby.

    it "should swap start for post_fork and call spawnp with args" do
      expect(@service).to receive(:remove_stale_pid_file).once
      expect(Raad).to receive(:jruby?).and_return(true)
      expect(Spoon).to receive(:spawnp).with(Raad.ruby_path, "-JXmx=256m", $0, "test", "post_fork")

      Raad.ruby_options = "-JXmx=256m"
      @service.daemonize(["test", "start"], 'test')
      Raad.ruby_options = ""
    end
  end

  describe "jruby daemonize (only in jruby)" do

    it "should daemonize" do
      expect(false).to be_falsy
    end
  end if Raad.jruby?

  describe "post_fork_setup" do

    it 'should create a pid file' do
      expect(STDIN).to receive(:reopen)
      expect(STDOUT).to receive(:reopen)
      expect(STDERR).to receive(:reopen)
      @service.post_fork_setup('test', nil)
      expect(File.exist?(@service.pid_file)).to be_truthy
      expect(@service.pid).to eq(Process.pid)
    end

    it 'should redirect stdio to a log file' do
      @service = TestService.new(@p)

      expect(STDIN).to receive(:reopen).with("/dev/null")
      expect(STDOUT).to receive(:reopen).with(@l, 'a')
      expect(STDERR).to receive(:reopen).with(STDOUT)

      @service.post_fork_setup('test', @l)
    end
  end

  describe 'read/write/remove pid file' do

    it 'should write pid file' do
      @service.write_pid_file
      expect(File.exist?(@service.pid_file)).to be_truthy
      expect(File.read(@p).to_i).to eq(Process.pid)
    end

    it 'should read pid file' do
      @service.write_pid_file
      expect(@service.read_pid_file).to eq(Process.pid)
    end

    it 'should remove pid file' do
      @service.write_pid_file
      expect(File.exist?(@service.pid_file)).to be_truthy
      @service.remove_pid_file
      expect(File.exist?(@service.pid_file)).to be_falsy
    end
  end

  describe 'send_signal' do

    it 'should send signal and terminate process' do
      @service.write_pid_file
      t = Thread.new{Thread.stop}
      Kernel.trap(:USR2) {Thread.new{t.run}}
      expect(Process).to receive(:running?).once.and_return(false)
      expect($stdout).to receive(:write).once # mute trace
      expect(@service.send_signal(:USR2, 5)).to be_truthy
      Timeout.timeout(5) {t.join}
    end

    it 'should force kill on Timeout::Error exception' do
      @service.write_pid_file
      expect(Process).to receive(:kill).and_raise(Timeout::Error)
      expect(@service).to receive(:force_kill_and_remove_pid_file).and_return(true)
      expect($stdout).to receive(:write).once # mute trace
      expect(@service.send_signal(:USR2, 5)).to be_truthy
    end

    it 'should force kill on Interrupt exception' do
      @service.write_pid_file
      expect(Process).to receive(:kill).and_raise(Interrupt)
      expect(@service).to receive(:force_kill_and_remove_pid_file).and_return(true)
      expect($stdout).to receive(:write).once # mute trace
      expect(@service.send_signal(:USR2, 5)).to be_truthy
    end

    it 'should remove pid file on Errno::ESRCH exception' do
      @service.write_pid_file
      expect(Process).to receive(:kill).and_raise(Errno::ESRCH)
      expect($stdout).to receive(:write).exactly(2).times # mute trace
      expect(@service).to receive(:remove_pid_file)
      expect(@service.send_signal(:USR2, 5)).to be_falsy
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
      expect(Process).to receive(:kill).with("KILL", 666).once
      expect($stdout).to receive(:write).once # mute trace
      expect(@service.force_kill_and_remove_pid_file(666)).to be_truthy
    end

    it 'should remove pid file on no such process exception' do
      @service.write_pid_file
      expect($stdout).to receive(:write).exactly(2).times # mute trace
      expect(Process).to receive(:kill).with("KILL", 666).once.and_raise(Errno::ESRCH)
      expect(@service).to receive(:remove_pid_file)
      expect(@service.force_kill_and_remove_pid_file(666)).to be_falsy
    end
  end
end
