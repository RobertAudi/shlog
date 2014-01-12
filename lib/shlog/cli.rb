module Shlog
  class CLI
    include Shlog::BasicCLI

    program_desc  "Command-line logging made easy"
    version       Shlog::VERSION
    desc          "A wrapper around lumberjack (https://github.com/bdurand/lumberjack) to make logging on the command line easier."

    arg_name "FILE"
    flag [:config]

    set_default_options!
    commands_from File.expand_path(File.join(File.dirname(File.realpath(__FILE__)), "commands"))

    pre do |global, command, options, args|
      config_files = CONFIG_FILES

      if global[:config]
        # If a config file is explicitely specified, it MUST exist!
        unless File.exists?(global[:config])
          raise RuntimeError, "Unable to find config file: #{global[:config]}"
        end

        config_files << global[:config]
      end

      config_files.each do |cf|
        begin
          next unless File.exists?(cf) && File.readable?(cf)

          config = Psych.load(ERB.new(IO.read(cf)).result)

          options.merge! config["commands"][command.name.to_sym]

          # Only merge the global options
          config.delete_if { |k, c| c.is_a?(Enumerable) }
          global.merge! config

          # TODO: Add a flag to skip other config files, maybe?
        rescue => e
          raise RuntimeError, "Unable to load config from '#{cf}': #{e.message}"
        end
      end

      true
    end

    on_error do |exception|
      puts exception.message.color(:red)

      false
    end
  end
end
