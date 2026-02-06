# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-strict-locals-comment-syntax.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-strict-locals-comment-syntax

module Herb
  module Lint
    module Rules
      # Rule that enforces correct syntax for strict locals magic comments.
      #
      # Rails strict locals allow partials to declare their expected local variables
      # using a magic comment at the top of the file. This rule validates that the
      # comment follows the correct format.
      #
      # Good:
      #   <%# locals: (user:, admin: false) %>
      #   <%# locals: () %>
      #   <%# locals: (name:, **attributes) %>
      #
      # Bad:
      #   <%# locals() %>            # Missing colon
      #   <%# local: (user:) %>      # Singular "local" instead of plural
      #   <%# locals:(user:) %>      # Missing space after colon
      #   <%# locals: user %>        # Missing parentheses
      #   <%# locals: (user) %>      # Positional argument (must be keyword)
      #   <% # locals: (user:) %>    # Ruby comment instead of ERB comment
      class ErbStrictLocalsCommentSyntax < VisitorRule
        include StringHelpers
        include FileHelpers

        def self.rule_name #: String
          "erb-strict-locals-comment-syntax"
        end

        def self.description #: String
          "Enforce correct syntax for strict locals magic comments"
        end

        def self.default_severity #: String
          "error"
        end

        # @rbs @seen_strict_locals_comment: bool
        # @rbs @first_strict_locals_location: Location?

        # @rbs override
        def on_new_investigation #: void
          super
          @seen_strict_locals_comment = false
          @first_strict_locals_location = nil
        end

        # @rbs override
        def visit_erb_content_node(node)
          content = node.content&.value
          return super unless content

          case node.tag_opening&.value
          when "<%#"
            check_erb_comment_node(node, content)
          when "<%", "<%-"
            check_ruby_comment_in_execution_tag(node, content)
          end

          super
        end

        private

        # @rbs node: Herb::AST::ERBContentNode
        # @rbs content: String
        def check_erb_comment_node(node, content) #: void
          comment_content = content.strip
          return unless looks_like_locals_declaration?(comment_content)

          check_partial_file(node)
          check_duplicate_declaration(node)

          validator = Validator.new(self)
          validator.validate(comment_content, node)
        end

        # @rbs node: Herb::AST::ERBContentNode
        def check_duplicate_declaration(node) #: void
          if @seen_strict_locals_comment
            add_offense(
              message: "Duplicate `locals:` declaration. Only one `locals:` comment is allowed per partial " \
                       "(first declaration at line #{@first_strict_locals_location&.start&.line}).",
              location: node.location
            )
          else
            @seen_strict_locals_comment = true
            @first_strict_locals_location = node.location
          end
        end

        # @rbs node: Herb::AST::ERBContentNode
        def check_partial_file(node) #: void
          is_partial = partial_file?(@context&.file_path)

          if is_partial == false # rubocop:disable Style/GuardClause
            add_offense(
              message: "Strict locals (`locals:`) only work in partials (files starting with `_`). " \
                       "This declaration will be ignored.",
              location: node.location
            )
          end
        end

        # @rbs node: Herb::AST::ERBContentNode
        # @rbs content: String
        def check_ruby_comment_in_execution_tag(node, content) #: void
          return unless ruby_comment_looks_like_locals_declaration?(content)

          add_offense(
            message: "Use `<%#` instead of `#{node.tag_opening&.value} #` for strict locals comments. " \
                     "Only ERB comment syntax is recognized by Rails.",
            location: node.location
          )
        end

        # @rbs content: String
        def looks_like_locals_declaration?(content) #: bool
          /\Alocals?\s*[:(]/.match?(content)
        end

        # @rbs content: String
        def ruby_comment_looks_like_locals_declaration?(content) #: bool
          /\A\s*#\s*locals?\s*[:(]/.match?(content)
        end

        # Validator for strict locals comment syntax
        # rubocop:disable Metrics/ClassLength
        class Validator
          include StringHelpers

          STRICT_LOCALS_PATTERN = /\Alocals:\s+\([^)]*\)\s*\z/

          # @rbs @rule: ErbStrictLocalsCommentSyntax

          # @rbs rule: ErbStrictLocalsCommentSyntax
          def initialize(rule)
            @rule = rule
          end

          # @rbs comment_content: String
          # @rbs node: Herb::AST::ERBContentNode
          def validate(comment_content, node) #: void
            unless balanced_parentheses?(comment_content)
              add_offense(
                message: "Unbalanced parentheses in `locals:` comment. " \
                         "Ensure all opening parentheses have matching closing parentheses.",
                location: node.location
              )
              return
            end

            if valid_strict_locals_format?(comment_content)
              handle_valid_format(comment_content, node)
            else
              handle_invalid_format(comment_content, node)
            end
          end

          private

          # @rbs content: String
          def valid_strict_locals_format?(content) #: bool
            STRICT_LOCALS_PATTERN.match?(content)
          end

          # @rbs comment_content: String
          # @rbs node: Herb::AST::ERBContentNode
          def handle_valid_format(comment_content, node) #: void
            params_match = comment_content.match(/\Alocals:\s*(\([\s\S]*\))\s*\z/)
            return unless params_match

            error = validate_locals_signature(params_match[1])
            add_offense(message: error, location: node.location) if error
          end

          # @rbs comment_content: String
          # @rbs node: Herb::AST::ERBContentNode
          # rubocop:disable Metrics/MethodLength
          def handle_invalid_format(comment_content, node) #: void
            case comment_content
            when /\Alocals\(/
              add_offense(
                message: "Use `locals:` with a colon, not `locals()`. Correct format: `<%# locals: (...) %>`.",
                location: node.location
              )
            when /\Alocal:/
              add_offense(
                message: "Use `locals:` (plural), not `local:`.",
                location: node.location
              )
            when /\Alocals\s+\(/
              add_offense(
                message: "Use `locals:` with a colon before the parentheses, not `locals (`.",
                location: node.location
              )
            when /\Alocals:\(/
              add_offense(
                message: "Missing space after `locals:`. Rails Strict Locals require a space after the colon: " \
                         "`<%# locals: (...) %>`.",
                location: node.location
              )
            when /\Alocals:\s*[^(]/
              add_offense(
                message: "Wrap parameters in parentheses: `locals: (name:)` or `locals: (name: default)`.",
                location: node.location
              )
            when /\Alocals:\s*\z/
              add_offense(
                message: "Add parameters after `locals:`. Use `locals: (name:)` or `locals: ()` for no locals.",
                location: node.location
              )
            else
              add_offense(
                message: "Invalid `locals:` syntax. Use format: `locals: (name:, option: default)`.",
                location: node.location
              )
            end
          end
          # rubocop:enable Metrics/MethodLength

          # @rbs params_content: String
          # @rbs return: String?
          def validate_locals_signature(params_content)
            match = params_content.match(/\A\s*\(([\s\S]*)\)\s*\z/)
            return nil unless match

            inner = match[1].strip
            return nil if inner.empty? # Empty locals is valid: locals: ()

            comma_error = validate_comma_usage(inner)
            return comma_error if comma_error

            params = split_by_top_level_comma(inner)

            params.each do |param|
              error = validate_parameter(param)
              return error if error
            end

            nil
          end

          # @rbs inner: String
          # @rbs return: String?
          def validate_comma_usage(inner)
            return unless inner.start_with?(",") || inner.end_with?(",") || /,,/.match?(inner)

            "Unexpected comma in `locals:` parameters."
          end

          # @rbs param: String
          # @rbs return: String?
          def validate_parameter(param)
            trimmed = param.strip
            return nil if trimmed.empty?

            validate_block_argument(trimmed) ||
              validate_splat_argument(trimmed) ||
              validate_double_splat_argument(trimmed) ||
              (trimmed.start_with?("**") ? nil : validate_keyword_argument(trimmed))
          end

          # @rbs param: String
          # @rbs return: String?
          def validate_block_argument(param)
            return unless param.start_with?("&")

            "Block argument `#{param}` is not allowed. Strict locals only support keyword arguments."
          end

          # @rbs param: String
          # @rbs return: String?
          def validate_splat_argument(param)
            return unless param.start_with?("*") && !param.start_with?("**")

            "Splat argument `#{param}` is not allowed. Strict locals only support keyword arguments."
          end

          # @rbs param: String
          # @rbs return: String?
          def validate_double_splat_argument(param)
            return unless param.start_with?("**")

            if /\A\*\*\w+\z/.match?(param)
              nil # Valid double-splat
            else
              "Invalid double-splat syntax `#{param}`. Use `**name` format (e.g., `**attributes`)."
            end
          end

          # @rbs param: String
          # @rbs return: String?
          def validate_keyword_argument(param)
            return if /\A\w+:\s*/.match?(param)

            if /\A\w+\z/.match?(param)
              "Positional argument `#{param}` is not allowed. Use keyword argument format: `#{param}:`."
            else
              "Invalid parameter `#{param}`. Use keyword argument format: `name:` or `name: default`."
            end
          end

          # @rbs message: String
          # @rbs location: Herb::Location
          def add_offense(message:, location:) #: void
            @rule.add_offense(message:, location:)
          end
        end
        # rubocop:enable Metrics/ClassLength
      end
    end
  end
end
