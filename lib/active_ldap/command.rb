require 'optparse'
require 'ostruct'

module ActiveLdap
  module Command
    module_function
    def parse_options(argv=nil, version=nil)
      argv ||= ARGV.dup
      options = OpenStruct.new
      opts = OptionParser.new do |opts|
        yield(opts, options)

        opts.separator ""
        opts.separator "Common options:"

        opts.on_tail("--config=CONFIG",
                     "Specify configuration file written as YAML") do |file|
          require 'yaml'
          config = YAML.load(File.read(file)).symbolize_keys
          Configuration::DEFAULT_CONFIG.update(config)
        end

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end

        opts.on_tail("--version", "Show version") do
          puts(version || VERSION)
          exit
        end
      end
      opts.parse!(argv)
      [argv, opts, options]
    end

    def read_password(prompt, input=$stdin, output=$stdout)
      output.print prompt
      system "/bin/stty -echo" if input.tty?
      input.gets.chomp
    ensure
      system "/bin/stty echo" if input.tty?
      output.puts
    end
  end
end
