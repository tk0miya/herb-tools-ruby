# frozen_string_literal: true

module Herb
  module Lint
    # Stateless parser for ERB directive comments.
    # Detects <%# herb:linter ignore %> and <%# herb:disable ... %> directives.
    #
    # DirectiveParser.parse is the only public entry point for full-file parsing.
    # parse_disable_comment_content and disable_comment_content? are also public
    # for use by meta-rules that inspect individual ERB comment nodes.
    class DirectiveParser
      HERB_DISABLE_PREFIX = "herb:disable" #: String
      HERB_LINTER_IGNORE_PREFIX = "herb:linter ignore" #: String

      # Parsed rule name with position information for error reporting.
      # offset is relative to the start of the ERB content token value.
      DisableRuleName = Data.define(
        :name,   #: String
        :offset, #: Integer
        :length  #: Integer
      )

      # Parsed herb:disable comment (including malformed ones).
      # match is true when the comment has a valid herb:disable format.
      # Malformed comments (match=false) are still stored for meta-rule validation.
      DisableComment = Data.define(
        :match,             #: bool
        :rule_names,        #: Array[String]
        :rule_name_details, #: Array[DisableRuleName]
        :rules_string,      #: String?
        :content_location   #: Herb::Location -- location of the ERB content token
      )

      # Parse result holding all directive information for a file.
      # Meta-rules access disable_comments directly for validation.
      Directives = Data.define(
        :ignore_file,      #: bool
        :disable_comments  #: Hash[Integer, DisableComment]
      ) do
        # Returns whether the file should be ignored entirely.
        def ignore_file? #: bool
          ignore_file
        end

        # Returns whether a rule is disabled on a given line.
        #
        # @rbs line: Integer -- 1-based line number
        # @rbs rule_name: String -- the rule name to check
        def disabled_at?(line, rule_name) #: bool
          comment = disable_comments[line]
          return false unless comment
          return false unless comment.match

          comment.rule_names.include?(rule_name) || comment.rule_names.include?("all")
        end

        # Filter offenses by disable comments.
        # Returns a tuple of [kept_offenses, ignored_offenses].
        #
        # @rbs offenses: Array[Herb::Lint::Offense]
        def filter_offenses(offenses) #: [Array[Herb::Lint::Offense], Array[Herb::Lint::Offense]]
          offenses.partition { |offense| !disabled_at?(offense.line, offense.rule_name) }
        end
      end

      # Parse all directives from a template.
      #
      # @rbs parse_result: Herb::ParseResult -- parsed document
      # @rbs source: String -- source code (reserved for future use)
      def self.parse(parse_result, source) #: Directives # rubocop:disable Lint/UnusedMethodArgument
        collector = Collector.new
        parse_result.visit(collector)

        Directives.new(
          ignore_file: collector.ignore_file,
          disable_comments: collector.disable_comments
        )
      end

      # Parse the content inside <%# ... %> delimiters.
      # Returns a DisableComment if the content starts with herb:disable prefix,
      # nil otherwise.
      #
      # @rbs content: String -- the text between <%# and %>
      # @rbs content_location: Herb::Location -- location of the ERB content token
      def self.parse_disable_comment_content(content, content_location:) #: DisableComment?
        stripped = content.strip
        return nil unless stripped.start_with?(HERB_DISABLE_PREFIX)

        rest = stripped[HERB_DISABLE_PREFIX.length..]
        return build_empty_disable_comment(content_location) if rest.nil? || rest.empty?
        return build_malformed_disable_comment(rest, content_location) unless rest.start_with?(" ")

        build_matched_disable_comment(content, rest[1..], content_location)
      end

      # Check if content (inside <%# ... %> delimiters) is a herb:disable comment.
      #
      # @rbs content: String -- the text between <%# and %>
      def self.disable_comment_content?(content) #: bool
        content.strip.start_with?(HERB_DISABLE_PREFIX)
      end

      # Build a DisableComment for herb:disable with no rules.
      # @rbs content_location: Herb::Location
      private_class_method def self.build_empty_disable_comment(content_location) #: DisableComment
        DisableComment.new(match: true, rule_names: [], rule_name_details: [], rules_string: nil, content_location:)
      end

      # Build a DisableComment for a malformed directive (no space after prefix).
      # @rbs rest: String
      # @rbs content_location: Herb::Location
      private_class_method def self.build_malformed_disable_comment(rest, content_location) #: DisableComment
        DisableComment.new(
          match: false, rule_names: [], rule_name_details: [],
          rules_string: rest, content_location:
        )
      end

      # Build a DisableComment for a valid herb:disable directive.
      # @rbs content: String -- full content value for offset calculation
      # @rbs rules_string: String -- the portion after "herb:disable "
      # @rbs content_location: Herb::Location
      # rubocop:disable Layout/LineLength
      private_class_method def self.build_matched_disable_comment(content, rules_string, content_location) #: DisableComment
        # rubocop:enable Layout/LineLength
        rule_name_details = extract_rule_names(content, rules_string)
        rule_names = rule_name_details.map(&:name)
        DisableComment.new(match: true, rule_names:, rule_name_details:, rules_string:, content_location:)
      end

      # Extract rule names with position information from the rules string.
      #
      # @rbs content: String -- full content value for offset calculation
      # @rbs rules_string: String -- the portion after "herb:disable "
      private_class_method def self.extract_rule_names(content, rules_string) #: Array[DisableRuleName]
        return [] if rules_string.nil? || rules_string.empty?

        rules_offset = content.index(rules_string)
        return [] if rules_offset.nil?

        details = [] #: Array[DisableRuleName]
        scanner_offset = 0

        rules_string.scan(/[^,\s]+/) do
          name = Regexp.last_match[0] #: String
          name_offset = rules_string.index(name, scanner_offset)
          next if name_offset.nil?

          details << DisableRuleName.new(
            name:,
            offset: rules_offset + name_offset,
            length: name.length
          )

          scanner_offset = name_offset + name.length
        end

        details
      end

      # Private visitor for AST traversal to collect directive comments.
      class Collector < Herb::Visitor
        attr_reader :ignore_file #: bool
        attr_reader :disable_comments #: Hash[Integer, DisableComment]

        def initialize #: void
          @ignore_file = false
          @disable_comments = {}
          super
        end

        # @rbs override
        def visit_erb_content_node(node)
          process_erb_comment(node) if node.tag_opening.value == "<%#"
          super
        end

        private

        # @rbs node: Herb::AST::ERBContentNode
        def process_erb_comment(node) #: void
          content = node.content.value
          line = node.location.start.line

          @ignore_file = true if content.strip == DirectiveParser::HERB_LINTER_IGNORE_PREFIX

          comment = DirectiveParser.parse_disable_comment_content(content, content_location: node.content.location)
          @disable_comments[line] = comment if comment
        end
      end
      private_constant :Collector
    end
  end
end
