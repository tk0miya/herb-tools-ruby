# frozen_string_literal: true

require "optparse"
require "herb/config"

module Herb
  module Lint
    # Command-line interface for herb-lint.
    class CLI
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
        execute_lint
      rescue SystemExit => e
        e.status
      rescue OptionParser::InvalidArgument => e
        handle_error("Invalid format: #{e.args.first}. Valid formats are: simple, json")
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

      def execute_lint #: Integer
        config_hash = Herb::Config::Loader.load
        config = Herb::Config::LinterConfig.new(config_hash)

        ignore_disable_comments = options[:ignore_disable_comments] || false
        fix = options[:fix] || false
        unsafe = options[:fix_unsafely] || false

        runner = Runner.new(config, ignore_disable_comments:, fix:, unsafe:)
        result = runner.run(argv)

        reporter = create_reporter
        reporter.report(result)

        result.success? ? EXIT_SUCCESS : EXIT_LINT_ERROR
      end

      # Parses command-line options using OptionParser.
      def parse_options #: void # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        parser = OptionParser.new do |opts| # rubocop:disable Metrics/BlockLength
          opts.banner = "Usage: herb-lint [options] [paths...]"

          opts.on("--version", "Show version") do
            stdout.puts "herb-lint #{VERSION}"
            exit EXIT_SUCCESS
          end

          opts.on("--help", "Show this help") do
            stdout.puts opts
            stdout.puts
            stdout.puts "Examples:"
            stdout.puts "  herb-lint                          # Lint all files in current directory"
            stdout.puts "  herb-lint app/views                # Lint files in app/views"
            stdout.puts "  herb-lint app/views/users/*.erb    # Lint specific files"
            stdout.puts "  herb-lint --format json .          # Output as JSON"
            stdout.puts "  herb-lint --github .               # Output GitHub Actions annotations"
            stdout.puts
            stdout.puts "Exit codes:"
            stdout.puts "  0  No offenses found"
            stdout.puts "  1  Offenses found"
            stdout.puts "  2  Runtime error (configuration error, file I/O error, etc.)"
            exit EXIT_SUCCESS
          end

          opts.on("--format TYPE", %w[simple json], "Output format (simple, json)") do |format|
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
        end

        parser.parse!(argv)
      end

      # Creates the appropriate reporter based on command-line options.
      def create_reporter #: Reporter::SimpleReporter | Reporter::JsonReporter | Reporter::GithubReporter
        return Reporter::GithubReporter.new(io: stdout) if options[:github]

        case options[:format]
        when "json"
          Reporter::JsonReporter.new(io: stdout)
        else
          Reporter::SimpleReporter.new(io: stdout)
        end
      end
    end
  end
end
