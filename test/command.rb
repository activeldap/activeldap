require "thread"
require "socket"
require "shellwords"

module Command
  class Error < StandardError
    attr_reader :command, :result
    def initialize(command, result)
      @command = command
      @result = result
      super("#{command}: #{result}")
    end
  end

  module_function
  def detach_io
    require 'fcntl'
    [TCPSocket, ::File].each do |c|
      ObjectSpace.each_object(c) do |io|
        begin
          unless io.closed?
            io.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
          end
        rescue SystemCallError,IOError => e
        end
      end
    end
  end

  def run(cmd, *args, &block)
    raise ArgumentError, "command isn't specified" if cmd.nil?
    if args.any? {|x| x.nil?}
      raise ArgumentError, "args has nil: #{args.inspect}"
    end
    return java_run(cmd, *args, &block) unless Kernel.respond_to?(:fork)
    in_r, in_w = IO.pipe
    out_r, out_w = IO.pipe
    pid = exit_status = nil
    Thread.exclusive do
      verbose = $VERBOSE
      # ruby(>=1.8)'s fork terminates other threads with warning messages
      $VERBOSE = nil
      pid = fork do
        $VERBOSE = verbose
        detach_io
        out = STDERR.dup
        STDIN.reopen(in_r)
        in_r.close
        STDOUT.reopen(out_w)
        STDERR.reopen(out_w)
        out_w.close
        exec(cmd, *args.collect {|arg| arg.to_s})
        exit!(-1)
      end
      $VERBOSE = verbose
    end
    yield(out_r, in_w) if block_given?
    in_r.close unless in_r.closed?
    out_w.close unless out_w.closed?
    pid, status = Process.waitpid2(pid)
    [status.exited? && status.exitstatus.zero?, out_r.read]
  end

  def java_run(cmd, *args, &block)
    runtime = java.lang.Runtime.get_runtime
    process = runtime.exec([cmd, *args].to_java(:string))
    input = java_stream_reader(process.get_input_stream)
    output = process.get_output_stream
    yield(input, output) if block_given?
    success = process.wait_for.zero?

    result = ""
    error = java_stream_reader(process.get_error_stream)
    [input, error].each do |stream|
      while line = stream.read_line
        result << "#{line}\n"
      end
    end
    [success, result]
  end

  def java_stream_reader(input)
    java.io.BufferedReader.new(java.io.InputStreamReader.new(input))
  end
end
