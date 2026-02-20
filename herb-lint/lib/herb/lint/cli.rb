# frozen_string_literal: true

require "optparse"
require "herb/config"

module Herb
  module Lint
    # Command-line interface for herb-lint.
    class CLI # rubocop:disable Metrics/ClassLength
      EXIT_SUCCESS = 0       #: Integer
      EXIT_LINT_ERROR = 1    #: Integer
      EXIT_RUNTIME_ERROR = 2 #: Integer

      # @rbs argv: Array[String]
      def initialize(argv) #: void
        @argv = argv
        @stdout = $stdout
        @stderr = $stderr
        @options = {}
      end

      def run #: Integer
        parse_options
        return initialize_config if options[:init]

        execute_lint
      rescue SystemExit => e
        e.status
      rescue OptionParser::InvalidArgument => e
        handle_error("Invalid format: #{e.args.first}. Valid formats are: simple, detailed, json")
      rescue Herb::Config::Error => e
        handle_error("Configuration error: #{e.message}")
      rescue StandardError => e
        handle_error("Error: #{e.message}", e.backtrace)
      end

      private

      attr_reader :argv #: Array[String]
      attr_reader :options #: Hash[Symbol, untyped]
      attr_reader :stdout #: IO
      attr_reader :stderr #: IO

      # @rbs message: String
      # @rbs backtrace: Array[String]?
      def handle_error(message, backtrace = nil) #: Integer
        stderr.puts message
        stderr.puts backtrace if backtrace && ENV["DEBUG"]
        EXIT_RUNTIME_ERROR
      end

      # Initializes a new .herb.yml configuration file
      def initialize_config #: Integer
        Herb::Config::Template.generate(base_dir: Dir.pwd)
        stdout.puts "Created .herb.yml"
        EXIT_SUCCESS
      rescue Herb::Config::Error => e
        stderr.puts "Error: #{e.message}"
        EXIT_RUNTIME_ERROR
      end

      # Calculate the exit code based on failLevel configuration.
      # Returns EXIT_LINT_ERROR if any offense meets or exceeds the failLevel threshold.
      def exit_code_for(result, config:) #: Integer
        return EXIT_SUCCESS if result.success?

        fail_level = options[:fail_level] || config.fail_level
        threshold = Severity.rank(fail_level)

        result.unfixed_offenses.any? { _1.severity_rank >= threshold } ? EXIT_LINT_ERROR : EXIT_SUCCESS
      end

      def execute_lint #: Integer
        config_hash = Herb::Config::Loader.load(path: options[:config_file])
        config = Herb::Config::LinterConfig.new(config_hash)

        runner = Runner.new(config, **runner_options)
        result = runner.run(argv)

        formatter = create_formatter
        formatter.report(result)

        exit_code_for(result, config:)
      end

      def runner_options #: Hash[Symbol, bool]
        {
          ignore_disable_comments: options[:ignore_disable_comments] || false,
          autofix: options[:fix] || false,
          unsafe: options[:fix_unsafely] || false,
          no_custom_rules: options[:no_custom_rules] || false
        }
      end

      # Parses command-line options using OptionParser.
      def parse_options #: void # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        parser = OptionParser.new do |opts| # rubocop:disable Metrics/BlockLength
          opts.banner = "Usage: herb-lint [options] [paths...]"

          opts.on("--version", "Show version") do
            stdout.puts "herb-lint #{VERSION}"
            exit EXIT_SUCCESS
          end

          opts.on("--init", "Generate a default .herb.yml configuration file") do
            options[:init] = true
          end

          opts.on("--help", "Show this help") do
            stdout.puts opts
            stdout.puts
            stdout.puts "Examples:"
            stdout.puts "  herb-lint --init                          # Generate a default .herb.yml configuration"
            stdout.puts "  herb-lint                                 # Lint all files in current directory"
            stdout.puts "  herb-lint app/views                       # Lint files in app/views"
            stdout.puts "  herb-lint app/views/users/*.erb           # Lint specific files"
            stdout.puts "  herb-lint --config-file path/to/.herb.yml # Use specified configuration file"
            stdout.puts "  herb-lint -c path/to/.herb.yml            # Use specified configuration file (short)"
            stdout.puts "  herb-lint --format detailed .             # Output with source code context"
            stdout.puts "  herb-lint --format json .                 # Output as JSON"
            stdout.puts "  herb-lint --github .                      # Output GitHub Actions annotations"
            stdout.puts "  herb-lint --fail-level warning .          # Exit with error on warnings or errors"
            stdout.puts
            stdout.puts "Exit codes:"
            stdout.puts "  0  No offenses found (or below fail level)"
            stdout.puts "  1  Offenses found at or above fail level"
            stdout.puts "  2  Runtime error (configuration error, file I/O error, etc.)"
            exit EXIT_SUCCESS
          end

          opts.on("-c", "--config-file PATH", "Use specified configuration file (disables upward search)") do |path|
            options[:config_file] = path
          end

          opts.on("--format TYPE", %w[simple detailed json], "Output format (simple, detailed, json)") do |format|
            options[:format] = format
          end

          opts.on("--github", "Output GitHub Actions annotations") do
            options[:github] = true
          end

          opts.on("--ignore-disable-comments", "Report offenses even when suppressed by herb:disable") do
            options[:ignore_disable_comments] = true
          end

          opts.on("--fix", "Apply safe automatic fixes") do
            options[:fix] = true
          end

          opts.on("--fix-unsafely", "Apply all fixes including unsafe ones") do
            options[:fix] = true
            options[:fix_unsafely] = true
          end

          opts.on("--no-custom-rules", "Skip loading custom rules from linter.custom_rules configuration") do
            options[:no_custom_rules] = true
          end

          opts.on("--fail-level LEVEL", %w[error warning info hint],
                  "Exit with error for violations at or above this level") do |level|
            options[:fail_level] = level
          end
        end

        parser.parse!(argv)
      end

      # Creates the appropriate formatter based on command-line options.
      def create_formatter #: Formatter::Base
        return Formatter::GitHubActionsFormatter.new(io: stdout) if options[:github]

        case options[:format]
        when "json"
          Formatter::JsonFormatter.new(io: stdout)
        when "simple"
          Formatter::SimpleFormatter.new(io: stdout)
        else
          Formatter::DetailedFormatter.new(io: stdout)
        end
      end
    end
  end
end
