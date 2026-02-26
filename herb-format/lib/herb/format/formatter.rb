# frozen_string_literal: true

module Herb
  module Format
    # Core single-file formatting implementation.
    class Formatter
      attr_reader :pre_rewriters  #: Array[Rewriters::Base]
      attr_reader :post_rewriters #: Array[Rewriters::Base]
      attr_reader :config         #: Herb::Config::FormatterConfig

      # @rbs pre_rewriters: Array[Rewriters::Base]
      # @rbs post_rewriters: Array[Rewriters::Base]
      # @rbs config: Herb::Config::FormatterConfig
      def initialize(pre_rewriters, post_rewriters, config) #: void
        @pre_rewriters = pre_rewriters
        @post_rewriters = post_rewriters
        @config = config
      end

      # Format a single file and return result.
      #
      # Processing flow:
      # 1. Parse ERB template into AST via Herb.parse
      # 2. If parsing fails, return source unchanged with error
      # 3. Check for ignore directive via FormatIgnore.ignore? (unless force)
      # 4. If ignored, return source unchanged with ignored flag
      # 5. Create Context with source and configuration
      # 6. Execute pre-rewriters (in order)
      # 7. Apply formatting via FormatPrinter.format(ast, format_context:)
      # 8. Return FormatResult with original and formatted content
      #
      # @rbs file_path: String
      # @rbs source: String
      # @rbs force: bool
      def format(file_path, source, force: false) #: FormatResult
        parse_result = Herb.parse(source, track_whitespace: true)

        if parse_result.errors.any?
          error = Errors::ParseError.new("Failed to parse #{file_path}: #{parse_result.errors.first.message}")
          return FormatResult.new(file_path:, original: source, formatted: source, error:)
        end

        ast = parse_result.value

        if !force && FormatIgnore.ignore?(ast)
          return FormatResult.new(file_path:, original: source, formatted: source, ignored: true)
        end

        context = Context.new(file_path:, source:, config:)
        format_with_context(file_path, source, ast, context)
      end

      private

      # @rbs file_path: String
      # @rbs source: String
      # @rbs ast: Herb::AST::DocumentNode
      # @rbs context: Context
      def format_with_context(file_path, source, ast, context) #: FormatResult
        ast = apply_rewriters(ast, pre_rewriters, context)
        formatted = FormatPrinter.format(ast, format_context: context)
        FormatResult.new(file_path:, original: source, formatted:)
      rescue StandardError => e
        FormatResult.new(file_path:, original: source, formatted: source, error: e)
      end

      # Apply rewriters to AST in order.
      #
      # @rbs ast: Herb::AST::DocumentNode
      # @rbs rewriters: Array[Rewriters::Base]
      # @rbs context: Context
      def apply_rewriters(ast, rewriters, context) #: Herb::AST::DocumentNode
        rewriters.reduce(ast) { |current_ast, rewriter| rewriter.rewrite(current_ast, context) }
      end
    end
  end
end
