require 'etc'
require 'timeout'

require 'raad/spoon' if Raad.jruby?

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
  
  def daemonize(argv, name, stdout_file = nil)
    remove_stale_pid_file
    pwd = Dir.pwd

    if Raad.jruby?
      # in jruby the process is to posix-spawn a new process and re execute ourself using Spoon.
      # swap command 'start' for 'post_fork' to signal the second exec
      spanw_options = [Raad.ruby_path].concat(Raad.ruby_options)
      spanw_options << $0
      spanw_options.concat(argv.map{|arg| arg == 'start' ? 'post_fork' : arg})
      Spoon.spawnp(*spanw_options)
    else
      # do the double fork dance
      Process.fork do
        Process.setsid
        exit if fork # exit parent
 
        Dir.chdir(pwd)
        post_fork_setup(name, stdout_file)

        yield
      end
    end
  end

  def post_fork_setup(name, stdout_file = nil)
    $0 = name # set process name, does not work with jruby

    File.umask(0000) # file mode creation mask to 000 to allow creation of files with any required permission late
    write_pid_file

    # redirect stdin, stdout, stderr
    STDIN.reopen('/dev/null')
    stdout_file ? STDOUT.reopen(stdout_file, "a") : STDOUT.reopen('/dev/null', 'a')
    STDERR.reopen(STDOUT)

    at_exit do
      remove_pid_file
    end
  end

  def send_signal(signal, timeout = 60)
    if pid = read_pid_file
      puts(">> sending #{signal} signal to process #{pid}")
      Process.kill(signal, pid)
      Timeout.timeout(timeout) do
        sleep 0.1 while Process.running?(pid)
      end
      true
    else
      puts(">> can't stop process, no pid found in #{@pid_file}")
      false
    end
  rescue Timeout::Error
    force_kill_and_remove_pid_file(pid)
  rescue Interrupt
    force_kill_and_remove_pid_file(pid)
  rescue Errno::ESRCH # No such process
    puts(">> can't stop process, no such process #{pid}")
    remove_pid_file
    false
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
