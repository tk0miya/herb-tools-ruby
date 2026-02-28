# frozen_string_literal: true

require "optparse"

module Herb
  module Highlighter
    # Command-line interface for herb-highlight.
    class CLI
      EXIT_SUCCESS = 0 #: Integer
      EXIT_ERROR = 1   #: Integer

      # @rbs argv: Array[String]
      def initialize(argv) #: void
        @argv = argv
        @stdout = $stdout
        @stderr = $stderr
        @options = {}
      end

      def run #: Integer
        parse_options
        execute_highlight
      rescue SystemExit => e
        e.status
      rescue OptionParser::InvalidArgument => e
        handle_error("Invalid argument: #{e.args.first}")
      rescue Errno::ENOENT
        handle_error("File not found: #{argv.first}")
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
        EXIT_ERROR
      end

      def execute_highlight #: Integer
        if argv.empty?
          stderr.puts "Please specify an input file."
          return EXIT_ERROR
        end

        filename = argv.first

        source = File.read(filename)
        theme_name = options[:theme] || Themes::DEFAULT_THEME

        highlighter = Highlighter.new(
          theme_name:,
          context_lines: options[:context_lines] || 2,
          tty: stdout.tty?
        )

        result = highlighter.highlight_source(source, focus_line: options[:focus])
        stdout.puts result
        EXIT_SUCCESS
      end

      def parse_options #: void # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        parser = OptionParser.new do |opts|
          opts.banner = "Usage: herb-highlight [options] FILE"

          opts.on("--version", "Print version and exit") do
            stdout.puts "herb-highlighter #{VERSION}"
            exit EXIT_SUCCESS
          end

          opts.on("--help", "Print usage and exit") do
            stdout.puts opts
            exit EXIT_SUCCESS
          end

          opts.on(
            "--theme THEME",
            "Color theme (built-in name or path to JSON file) [default: #{Themes::DEFAULT_THEME}]"
          ) do |theme|
            options[:theme] = theme
          end

          opts.on("--focus LINE", Integer, "Line number to focus on (1-based)") do |line|
            options[:focus] = line
          end

          opts.on(
            "--context-lines N",
            Integer,
            "Number of context lines around focus line [default: 2]"
          ) do |n|
            options[:context_lines] = n
          end
        end

        parser.parse!(argv)
      end
    end
  end
end
