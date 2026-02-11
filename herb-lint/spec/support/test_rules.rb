# frozen_string_literal: true

# Shared test rules for autofix testing across multiple spec files
module TestRules
  # Safe autofixable rule that clears the body of <div> elements
  #
  # Used in: autofixer_spec.rb, runner_spec.rb, autofix_context_spec.rb
  class SafeFixableRule < Herb::Lint::Rules::VisitorRule
    def self.rule_name = "test/safe-fixable"
    def self.description = "Test safe fixable rule"
    def self.default_severity = "warning"
    def self.safe_autofixable? = true
    def self.unsafe_autofixable? = false

    def visit_html_element_node(node)
      if tag_name(node) == "div"
        add_offense_with_autofix(
          message: "Div should be empty",
          location: node.location,
          node:
        )
      end
      super
    end

    def autofix(node, _parse_result)
      node.body.clear
      true
    end
  end

  # Unsafe autofixable rule that clears the body of <span> elements
  #
  # Used in: autofixer_spec.rb, runner_spec.rb, autofix_context_spec.rb
  class UnsafeFixableRule < Herb::Lint::Rules::VisitorRule
    def self.rule_name = "test/unsafe-fixable"
    def self.description = "Test unsafe fixable rule"
    def self.default_severity = "warning"
    def self.safe_autofixable? = false
    def self.unsafe_autofixable? = true

    def visit_html_element_node(node)
      if tag_name(node) == "span"
        add_offense_with_autofix(
          message: "Span should be empty",
          location: node.location,
          node:
        )
      end
      super
    end

    def autofix(node, _parse_result)
      node.body.clear
      true
    end
  end

  # Failing autofixable rule whose autofix always returns false
  #
  # Used in: autofixer_spec.rb
  class FailingFixableRule < Herb::Lint::Rules::VisitorRule
    def self.rule_name = "test/failing-fixable"
    def self.description = "Test failing fixable rule"
    def self.default_severity = "warning"
    def self.safe_autofixable? = true
    def self.unsafe_autofixable? = false

    def visit_html_element_node(node)
      add_offense_with_autofix(
        message: "This will fail to fix",
        location: node.location,
        node:
      )
      super
    end

    def autofix(_node, _parse_result)
      false
    end
  end

  # Safe source rule that removes trailing whitespace
  #
  # Used in: autofixer_spec.rb
  class SafeSourceRule < Herb::Lint::Rules::SourceRule
    def self.rule_name = "test/safe-source"
    def self.description = "Test safe source rule"
    def self.default_severity = "warning"
    def self.safe_autofixable? = true
    def self.unsafe_autofixable? = false

    def check_source(source, _context)
      # Find trailing whitespace at end of lines
      source.scan(/[ \t]+$/) do
        match_start = Regexp.last_match.offset(0)[0]
        match_end = Regexp.last_match.offset(0)[1]
        location = location_from_offsets(match_start, match_end)

        add_offense_with_source_autofix(
          message: "Remove trailing whitespace",
          location:,
          start_offset: match_start,
          end_offset: match_end
        )
      end
    end

    def autofix_source(offense, source)
      ctx = offense.autofix_context
      # Verify offsets are within bounds
      return nil if ctx.start_offset >= source.length
      return nil if ctx.end_offset > source.length

      # Verify the content at the offset is still whitespace
      content = source[ctx.start_offset...ctx.end_offset]
      return nil unless content&.match?(/\A[ \t]+\z/)

      # Remove the trailing whitespace
      source[0...ctx.start_offset] + source[ctx.end_offset..]
    end
  end

  # Failing source rule whose autofix_source always returns nil
  #
  # Used in: autofixer_spec.rb
  class FailingSourceRule < Herb::Lint::Rules::SourceRule
    def self.rule_name = "test/failing-source"
    def self.description = "Test failing source rule"
    def self.default_severity = "warning"
    def self.safe_autofixable? = true
    def self.unsafe_autofixable? = false

    def check_source(source, _context)
      # Find trailing whitespace at end of lines
      source.scan(/[ \t]+$/) do
        match_start = Regexp.last_match.offset(0)[0]
        match_end = Regexp.last_match.offset(0)[1]
        location = location_from_offsets(match_start, match_end)

        add_offense_with_source_autofix(
          message: "Will fail to fix",
          location:,
          start_offset: match_start,
          end_offset: match_end
        )
      end
    end

    def autofix_source(_offense, _source)
      # Always fail
      nil
    end
  end
end
