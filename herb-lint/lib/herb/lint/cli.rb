# frozen_string_literal: true

require "herb/config"

module Herb
  module Lint
    # Command-line interface for herb-lint.
    class CLI
      EXIT_SUCCESS = 0       #: Integer
      EXIT_LINT_ERROR = 1    #: Integer
      EXIT_RUNTIME_ERROR = 2 #: Integer

      HELP_TEXT = <<~HELP #: String
        Usage: herb-lint [options] [paths...]

        Options:
          --version    Show version
          --help       Show this help

        Examples:
          herb-lint                          # Lint all files in current directory
          herb-lint app/views                # Lint files in app/views
          herb-lint app/views/users/*.erb    # Lint specific files

        Exit codes:
          0  No offenses found
          1  Offenses found
          2  Runtime error (configuration error, file I/O error, etc.)
      HELP

      # @rbs argv: Array[String]
      def initialize(argv) #: void
        @argv = argv
        @stdout = $stdout
        @stderr = $stderr
      end

      def run #: Integer
        return EXIT_SUCCESS if handle_option?

        execute_lint
      rescue Herb::Config::Error => e
        handle_error("Configuration error: #{e.message}")
      rescue StandardError => e
        handle_error("Error: #{e.message}", e.backtrace)
      end

      private

      attr_reader :argv #: Array[String]

      # Returns true if an option was handled, false otherwise.
      def handle_option? #: bool
        if @argv.include?("--version")
          @stdout.puts "herb-lint #{VERSION}"
          true
        elsif @argv.include?("--help")
          print_help
          true
        else
          false
        end
      end

      # @rbs message: String
      # @rbs backtrace: Array[String]?
      def handle_error(message, backtrace = nil) #: Integer
        @stderr.puts message
        @stderr.puts backtrace if backtrace && ENV["DEBUG"]
        EXIT_RUNTIME_ERROR
      end

      def execute_lint #: Integer
        config_hash = Herb::Config::Loader.load
        config = Herb::Config::LinterConfig.new(config_hash)

        paths = argv.reject { |arg| arg.start_with?("-") }

        runner = Runner.new(config)
        result = runner.run(paths)

        reporter = Reporter::SimpleReporter.new
        reporter.report(result)

        result.success? ? EXIT_SUCCESS : EXIT_LINT_ERROR
      end

      def print_help #: void
        @stdout.puts HELP_TEXT
      end
    end
  end
end
