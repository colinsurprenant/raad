# Copyright (c) 2011 Praized Media Inc.
# Author: Colin Surprenant (colin.surprenant@needium.com, colin.surprenant@gmail.com, @colinsurprenant, http://github.com/colinsurprenant)

require 'etc'
require 'timeout'

module Process

  def running?(pid)
    Process.getpgid(pid) != -1
  rescue Errno::EPERM
    true
  rescue Errno::ESRCH
    false
  end

  module_function :running?
end

# Raised when the pid file already exist starting as a daemon.
class PidFileExist < RuntimeError; end

# module Daemonizable requires that the including class defines the @pid_file instance variable
module Daemonizable
    
  def pid
    File.exist?(@pid_file) ? open(@pid_file).read.to_i : nil
  end
  
  def daemonize(name, stdout_file)
    remove_stale_pid_file
    pwd = Dir.pwd

    # do the double fork dance
    Process.fork do
      Process.setsid
      exit if fork
      $0 = name # set process name

      File.umask(0000) # file mode creation mask to 000 to allow creation of files with any required permission late
      Dir.chdir(pwd)
      write_pid_file

      # redirect stdout into a log
      STDIN.reopen('/dev/null')
      stdout_file ? STDOUT.reopen(stdout_file, "a") : STDOUT.reopen('/dev/null', 'a')
      STDERR.reopen(STDOUT)

      at_exit do
        remove_pid_file
      end

      yield
    end
  end

  def send_signal(signal, timeout = 60)
    if pid = read_pid_file
      puts(">> sending #{signal} signal to process #{pid}")
      Process.kill(signal, pid)
      Timeout.timeout(timeout) do
        sleep 0.1 while Process.running?(pid)
      end
    else
      puts(">> can't stop process, no pid found in #{@pid_file}")
    end
  rescue Timeout::Error
    force_kill
  rescue Interrupt
    force_kill
  rescue Errno::ESRCH # No such process
    force_kill
  end
  
  def force_kill
    if pid = read_pid_file
      puts(">> sending KILL signal to process #{pid}")
      Process.kill("KILL", pid)
      File.delete(@pid_file) if File.exist?(@pid_file)
    else
      puts(">> can't stop process, no pid found in #{@pid_file}")
    end
  end
  
  def read_pid_file
    if File.file?(@pid_file) && pid = File.read(@pid_file)
      pid.to_i
    else
      nil
    end
  end

  def remove_pid_file
    File.delete(@pid_file) if @pid_file && File.exists?(@pid_file)
  end

  def write_pid_file
    puts(">> writing pid to #{@pid_file}")
    open(@pid_file,"w") { |f| f.write(Process.pid) }
    File.chmod(0644, @pid_file)
  end

  def remove_stale_pid_file
    if File.exist?(@pid_file)
      if pid && Process.running?(pid)
        raise PidFileExist, "#{@pid_file} exists and process #{pid} is runnig. stop the process or delete #{@pid_file}"
      else
        puts(">> deleting stale pid file #{@pid_file}")
        remove_pid_file
      end
    end
  end

end
