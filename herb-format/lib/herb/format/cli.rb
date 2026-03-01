# frozen_string_literal: true

require "herb/config"
require "optparse"

module Herb
  module Format
    # Command-line interface orchestration.
    class CLI # rubocop:disable Metrics/ClassLength
      EXIT_SUCCESS = 0       #: Integer
      EXIT_FORMAT_NEEDED = 1 #: Integer
      EXIT_RUNTIME_ERROR = 2 #: Integer

      # @rbs argv: Array[String]
      # @rbs stdout: IO
      # @rbs stderr: IO
      # @rbs stdin: IO
      def initialize(argv = ARGV, stdout: $stdout, stderr: $stderr, stdin: $stdin) #: void
        @argv = argv
        @stdout = stdout
        @stderr = stderr
        @stdin = stdin
      end

      # Run CLI and return exit code.
      #
      # Processing flow:
      # 1. Parse command-line options
      # 2. Handle special flags (--init, --version, --help)
      # 3. Load configuration via Herb::Config::Loader
      # 4. Create and run Runner (stdin or file mode)
      # 5. Report results (diff output in check mode)
      # 6. Determine exit code based on formatting results
      def run #: Integer
        parse_options

        return handle_version if options[:version]
        return handle_help if options[:help]
        return handle_init if options[:init]

        execute_format
      rescue Herb::Config::Error => e
        handle_error("Configuration error: #{e.message}")
      rescue StandardError => e
        handle_error("Error: #{e.message}")
      end

      private

      attr_reader :argv    #: Array[String]
      attr_reader :options #: Hash[Symbol, untyped]
      attr_reader :stdout  #: IO
      attr_reader :stderr  #: IO
      attr_reader :stdin   #: IO

      # @rbs message: String
      def handle_error(message) #: Integer
        stderr.puts message
        EXIT_RUNTIME_ERROR
      end

      def parse_options #: void # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        @options = {
          check: false,
          force: false,
          config: nil,
          version: false,
          help: false,
          files: []
        }

        OptionParser.new do |opts|
          opts.banner = "Usage: herb-format [options] [files...]"

          opts.on("--check", "Check if files are formatted without modifying them") do
            options[:check] = true
          end

          opts.on("--config PATH", "Path to configuration file (default: .herb.yml)") do |path|
            options[:config] = path
          end

          opts.on("--force", "Override inline ignore directives") do
            options[:force] = true
          end

          opts.on("-h", "--help", "Show help message") do
            options[:help] = true
          end

          opts.on("--init", "Generate a default .herb.yml configuration file") do
            options[:init] = true
          end

          opts.on("-v", "--version", "Show version number") do
            options[:version] = true
          end
        end.parse!(argv)

        options[:files] = argv.dup
      end

      def execute_format #: Integer
        files = options[:files]
        runner = Runner.new(
          config: load_config,
          check: options[:check],
          force: options[:force]
        )

        if files.first == "-" || (files.empty? && !stdin.isatty)
          format_stdin(runner)
        else
          format_files(runner, files)
        end
      end

      # @rbs runner: Runner
      def format_stdin(runner) #: Integer
        result = runner.format_source(stdin.read, file_path: "stdin")

        if result.error?
          stderr.puts "Error formatting stdin: #{result.error.message}"
          return EXIT_RUNTIME_ERROR
        end

        stdout.print ensure_newline(result.formatted)
        EXIT_SUCCESS
      end

      # @rbs runner: Runner
      # @rbs files: Array[String]
      def format_files(runner, files) #: Integer
        result = runner.run(files)

        report_results(result)
        determine_exit_code(result, options[:check])
      end

      def load_config #: Herb::Config::FormatterConfig
        config_hash = Herb::Config::Loader.load(path: options[:config])
        Herb::Config::FormatterConfig.new(config_hash)
      end

      # @rbs result: AggregatedResult
      def report_results(result) #: void
        if options[:check]
          report_check_results(result)
        else
          report_format_results(result)
        end
      end

      # @rbs result: AggregatedResult
      # @rbs check_mode: bool
      def determine_exit_code(result, check_mode) #: Integer
        return EXIT_RUNTIME_ERROR if result.error_count.positive?
        return EXIT_FORMAT_NEEDED if check_mode && result.changed_count.positive?

        EXIT_SUCCESS
      end

      def handle_version #: Integer
        stdout.puts "herb-format #{Herb::Format::VERSION}"
        EXIT_SUCCESS
      end

      def handle_help #: Integer
        stdout.puts <<~HELP
          Usage: herb-format [options] [files...]

          Options:
            --check                   Check if files are formatted without modifying them
            --config PATH             Path to configuration file (default: .herb.yml)
            --force                   Override inline ignore directives
            -h, --help                Show this help message
            --init                    Generate a default .herb.yml configuration file
            -v, --version             Show version number

          Examples:
            # Format all files in current directory
            herb-format

            # Format specific files
            herb-format app/views/users/index.html.erb

            # Check without modifying (for CI)
            herb-format --check

            # Format from stdin
            echo '<div><p>Hello</p></div>' | herb-format
            herb-format -

            # Initialize configuration
            herb-format --init

          Documentation: https://github.com/marcoroth/herb
        HELP
        EXIT_SUCCESS
      end

      def handle_init #: Integer
        Herb::Config::Template.generate(base_dir: Dir.pwd)
        stdout.puts "Created .herb.yml"
        EXIT_SUCCESS
      rescue Herb::Config::Error => e
        stderr.puts "Error: #{e.message}"
        EXIT_RUNTIME_ERROR
      rescue StandardError => e
        stderr.puts "Error creating configuration file: #{e.message}"
        EXIT_RUNTIME_ERROR
      end

      # @rbs result: AggregatedResult
      def report_check_results(result) #: void # rubocop:disable Metrics/AbcSize
        result.results.each do |file_result|
          next unless file_result.changed?

          stdout.puts file_result.file_path
          if file_result.diff
            stdout.puts file_result.diff
            stdout.puts
          end
        end

        stdout.puts "Checked #{result.file_count} files"
        stdout.puts "  #{result.changed_count} files need formatting"
        stdout.puts "  #{result.ignored_count} files ignored"
        stdout.puts "  #{result.error_count} files with errors" if result.error_count.positive?
      end

      # @rbs result: AggregatedResult
      def report_format_results(result) #: void # rubocop:disable Metrics/AbcSize
        result.results.each do |file_result|
          if file_result.error?
            stderr.puts "Error formatting #{file_result.file_path}: #{file_result.error.message}"
          elsif file_result.ignored?
            stdout.puts "Ignored: #{file_result.file_path}"
          elsif file_result.changed?
            stdout.puts "Formatted: #{file_result.file_path}"
          end
        end

        stdout.puts
        stdout.puts "Formatted #{result.file_count} files"
        stdout.puts "  #{result.changed_count} files changed"
        stdout.puts "  #{result.ignored_count} files ignored"
        stdout.puts "  #{result.error_count} files with errors" if result.error_count.positive?
      end

      # @rbs str: String
      def ensure_newline(str) #: String
        str.end_with?("\n") ? str : "#{str}\n"
      end
    end
  end
end
