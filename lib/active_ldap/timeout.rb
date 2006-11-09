require 'timeout'

module Timeout

  # A forking timeout implementation that relies on
  # signals to interrupt blocking I/O instead of passing
  # that code to run in a separate process.
  #
  # A process is fork()ed, sleeps for _sec_,
  # then sends a ALRM signal to the Process.ppid
  # process. ALRM is used to avoid conflicts with sleep()
  #
  # This overwrites any signal
  def Timeout.alarm(sec, exception=Timeout::Error, &block)
    return block.call if sec == nil or sec.zero?
 
  
    # Trap an alarm in case it comes before we're ready
    orig_alrm = trap(:ALRM, 'IGNORE')

    # Setup a fallback in case of a race condition of an
    # alarm before we set the other trap
    trap(:ALRM) do 
      # Don't leave zombies
      Process.wait2()
      # Restore the original handler
      trap('ALRM', orig_alrm)
      # Now raise an exception!
      raise exception, 'execution expired'
    end

    # Spawn the sleeper
    pid = Process.fork {
      begin
        # Sleep x seconds then send SIGALRM 
        sleep(sec)
        # Send alarm!
        Process.kill(:ALRM, Process.ppid)
      end
      exit! 0
    }

    # Setup the real handler
    trap(:ALRM) do
      # Make sure we clean up any zombies
      Process.waitpid(pid)
      # Restore the original handler
      trap(:ALRM, orig_alrm)
      # Now raise an exception!
      raise exception, 'execution expired'
    end

    begin
      # Run the code!
      return block.call
    ensure
      # Restore old alarm handler since we're done
      trap(:ALRM, orig_alrm)
      # Make sure the process is dead
      # This may be run twice (trap occurs during execution) so ignore ESRCH
      Process.kill(:TERM, pid) rescue Errno::ESRCH
      # Don't leave zombies
      Process.waitpid(pid) rescue Errno::ECHILD
    end
  end
end # Timeout

if __FILE__ == $0
  require 'time'
  Timeout.alarm(2) do 
    loop do 
      p Time.now
    end
  end
end
