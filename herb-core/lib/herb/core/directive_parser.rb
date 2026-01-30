# frozen_string_literal: true

module Herb
  module Core
    # Constants for directive types.
    module DirectiveType
      DISABLE = "disable" #: String
      ENABLE = "enable" #: String
      IGNORE_FILE = "ignore_file" #: String
    end

    # Constants for directive scopes.
    module DirectiveScope
      FILE = "file" #: String
      NEXT_LINE = "next_line" #: String
      RANGE_END = "range_end" #: String
    end

    # Represents a parsed inline directive from an ERB comment.
    Directive = Data.define(
      :type,  #: String
      :rules, #: Array[String]
      :line,  #: Integer
      :scope  #: String
    )

    # Parses inline directives by traversing the herb AST for ERB comment nodes.
    #
    # Supports the following directive formats:
    #   <%# herb:disable rule-name %>          - Disable a rule for the next line
    #   <%# herb:disable rule1, rule2 %>       - Disable multiple rules for the next line
    #   <%# herb:disable all %>                - Disable all rules for the next line
    #   <%# herb:enable rule-name %>           - Re-enable a rule
    #   <%# herb:enable all %>                 - Re-enable all rules
    #   <%# herb:linter ignore %>              - Ignore the entire file (in linter mode)
    class DirectiveParser < Herb::Visitor
      DIRECTIVE_PATTERN = /\Aherb:(disable|enable)\s+(.*)\z/ #: Regexp
      IGNORE_PATTERN = /\Aherb:(\w+)\s+ignore\z/ #: Regexp

      attr_reader :document #: Herb::ParseResult
      attr_reader :mode #: Symbol

      # @rbs @parse: Array[Directive]?
      # @rbs @collected_directives: Array[Directive]

      # @rbs document: Herb::ParseResult -- the parsed document from Herb.parse
      # @rbs mode: Symbol -- the tool mode (:linter or :formatter)
      def initialize(document, mode: :linter) #: void
        super()
        @document = document
        @mode = mode
      end

      # Parses all directives from the document AST.
      def parse #: Array[Directive]
        @parse ||= parse_directives
      end

      # Returns true if the file should be ignored entirely.
      def ignore_file? #: bool
        parse.any? { |d| d.type == DirectiveType::IGNORE_FILE }
      end

      # Returns true if the given rule (or all rules) is disabled at the specified line.
      #
      # @rbs line: Integer -- 1-based line number
      # @rbs rule_name: String? -- the rule name to check, or nil to check if any rule is disabled
      def disabled_at?(line, rule_name = nil) #: bool
        parse.any? do |directive|
          next false unless directive.type == DirectiveType::DISABLE
          next false unless directive.line + 1 == line
          next true if directive.rules.empty?

          rule_name.nil? || directive.rules.include?(rule_name)
        end
      end

      # @rbs override
      def visit_erb_content_node(node) #: void
        if node.tag_opening.value == "<%#"
          directive = parse_comment(node)
          @collected_directives << directive if directive
        end
        super
      end

      private

      def parse_directives #: Array[Directive]
        @collected_directives = []
        document.visit(self)
        @collected_directives
      end

      # @rbs node: Herb::AST::ERBContentNode
      def parse_comment(node) #: Directive?
        content = node.content.value.strip
        line = node.location.start.line

        parse_ignore_content(content, line) ||
          parse_disable_enable_content(content, line)
      end

      # @rbs content: String
      # @rbs line: Integer
      def parse_ignore_content(content, line) #: Directive?
        match = content.match(IGNORE_PATTERN)
        return unless match
        return unless match[1] == mode.to_s

        Directive.new(
          type: DirectiveType::IGNORE_FILE,
          rules: [],
          line:,
          scope: DirectiveScope::FILE
        )
      end

      # @rbs content: String
      # @rbs line: Integer
      def parse_disable_enable_content(content, line) #: Directive?
        match = content.match(DIRECTIVE_PATTERN)
        return unless match

        action = match[1]
        rules_part = match[2].to_s.strip
        return if rules_part.empty?

        type = action == "disable" ? DirectiveType::DISABLE : DirectiveType::ENABLE
        scope = action == "disable" ? DirectiveScope::NEXT_LINE : DirectiveScope::RANGE_END
        rules = parse_rules(rules_part)

        Directive.new(type:, rules:, line:, scope:)
      end

      # @rbs rules_part: String
      def parse_rules(rules_part) #: Array[String]
        return [] if rules_part == "all"

        rules_part.split(",").map(&:strip).reject(&:empty?)
      end
    end
  end
end
