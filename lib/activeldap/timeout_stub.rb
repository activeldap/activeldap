require 'timeout'

module Timeout
  # STUB
  def Timeout.alarm(sec, exception=Timeout::Error, &block)
    return block.call
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
