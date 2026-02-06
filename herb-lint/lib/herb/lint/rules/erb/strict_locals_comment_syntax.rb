# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-strict-locals-comment-syntax.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-strict-locals-comment-syntax

module Herb
  module Lint
    module Rules
      module Erb
        # Rule that enforces correct syntax for strict_locals magic comments.
        #
        # Uses StrictLocalsValidator to detect and validate locals declarations
        # in ERB comment tags. Also detects locals declarations in statement tags
        # (`<% # locals: ... %>`) and duplicate declarations.
        #
        # Good:
        #   <%# locals: (name:) %>
        #   <%# locals: (name:, age: 0) %>
        #   <%# locals: () %>
        #
        # Bad:
        #   <%# locals: (name) %>
        #   <%# locals(name:) %>
        #   <%# local: (name:) %>
        #   <% # locals: (name:) %>
        class StrictLocalsCommentSyntax < VisitorRule
          STATEMENT_TAG_COMMENT_PATTERN = /\A\s*#\s*/

          def self.rule_name #: String
            "erb-strict-locals-comment-syntax"
          end

          def self.description #: String
            "Enforce correct syntax for strict_locals magic comment"
          end

          def self.default_severity #: String
            "error"
          end

          # @rbs @first_locals_line: Integer?

          # @rbs override
          def on_new_investigation #: void
            super
            @first_locals_line = nil
          end

          # @rbs override
          def visit_erb_content_node(node)
            case node.tag_opening.value
            when "<%", "<%-"
              check_statement_tag(node)
            when "<%#"
              check_comment_tag(node)
            end
            super
          end

          private

          # Check a statement tag (`<% ... %>` / `<%- ... %>`) for locals declarations
          # written as Ruby comments (e.g. `<% # locals: (name:) %>`).
          # @rbs node: Herb::AST::ERBContentNode
          def check_statement_tag(node) #: void
            content = node.content&.value
            return if content.nil?
            return unless content.match?(STATEMENT_TAG_COMMENT_PATTERN)

            # Extract the part after the Ruby comment marker
            comment_body = content.sub(STATEMENT_TAG_COMMENT_PATTERN, "")
            return unless StrictLocalsValidator.locals_declaration?(comment_body.strip)

            add_offense(
              message: "Use `<%#` instead of `<% #` for strict locals comments. " \
                       "Only ERB comment syntax is recognized by Rails.",
              location: node.location
            )
          end

          # Check an ERB comment tag (`<%# ... %>`) for locals declarations.
          # @rbs node: Herb::AST::ERBContentNode
          def check_comment_tag(node) #: void # rubocop:disable Metrics/MethodLength
            content = node.content&.value
            return if content.nil?

            content_stripped = content.strip
            return unless StrictLocalsValidator.locals_declaration?(content_stripped)

            unless partial_file?
              add_offense(
                message: "`locals:` declaration found in a non-partial file. " \
                         "Strict locals are only supported in partial templates (files starting with `_`).",
                location: node.location
              )
              return
            end

            if locals_already_declared?(node)
              add_offense(
                message: "Duplicate `locals:` declaration. " \
                         "Only one `locals:` comment is allowed per partial " \
                         "(first declaration at line #{@first_locals_line}).",
                location: node.location
              )
              return
            end

            error = StrictLocalsValidator.validate(content_stripped)
            return unless error

            add_offense(message: error, location: node.location)
          end

          # Check if the current file is a partial (basename starts with underscore).
          def partial_file? #: bool
            File.basename(@context.file_path).start_with?("_")
          end

          # Track first locals declaration line. Returns true if a declaration was already seen.
          # @rbs node: Herb::AST::ERBContentNode
          def locals_already_declared?(node) #: bool
            if @first_locals_line.nil?
              @first_locals_line = node.location.start.line
              false
            else
              true
            end
          end
        end
      end
    end
  end
end
