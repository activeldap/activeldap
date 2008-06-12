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
    return java_run(cmd, *args, &block) unless Object.respond_to?(:java)
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
    input = JavaReaderWrapper.new(process.get_input_stream)
    output = JavaWriterWrapper.new(process.get_output_stream)
    error = JavaReaderWrapper.new(process.get_error_stream)
    yield(input, output) if block_given?
    output.close
    success = process.wait_for.zero?

    [success, input.read + error.read]
  end

  class JavaReaderWrapper
    def initialize(input)
      @input = input
    end

    def read
      result = ""
      while (c = @input.read) != -1
        result << c.chr
      end
      result
    end
  end

  class JavaWriterWrapper
    def initialize(output)
      output = java.io.OutputStreamWriter.new(output)
      @output = java.io.BufferedWriter.new(output)
    end

    def puts(*messages)
      messages.each do |message|
        message += "\n" if /\n/ !~ message
        @output.write(message)
      end
    end

    def flush
      @output.flush
    end

    def close
      @output.close
    end
  end
end
