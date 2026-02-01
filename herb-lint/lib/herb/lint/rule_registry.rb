# frozen_string_literal: true

module Herb
  module Lint
    # Registry for managing lint rules.
    # Provides registration, lookup, and loading of built-in and custom rules.
    class RuleRegistry
      # @rbs @rules: Hash[String, singleton(Rules::Base) | singleton(Rules::VisitorRule)]

      # Built-in rule classes shipped with herb-lint.
      # rubocop:disable Metrics/MethodLength
      def self.builtin_rules #: Array[singleton(Rules::Base) | singleton(Rules::VisitorRule)]
        @builtin_rules ||= [
          Rules::ErbCommentSyntax,
          Rules::HerbDisableCommentMalformed,
          Rules::HerbDisableCommentMissingRules,
          Rules::HerbDisableCommentNoDuplicateRules,
          Rules::HerbDisableCommentNoRedundantAll,
          Rules::HerbDisableCommentValidRuleName,
          Rules::HtmlAnchorRequireHref,
          Rules::HtmlAriaAttributeMustBeValid,
          Rules::HtmlAriaLabelIsWellFormatted,
          Rules::HtmlAriaLevelMustBeValid,
          Rules::HtmlAriaRoleHeadingRequiresLevel,
          Rules::HtmlAriaRoleMustBeValid,
          Rules::HtmlAttributeDoubleQuotes,
          Rules::HtmlAttributeEqualsSpacing,
          Rules::HtmlAttributeValuesRequireQuotes,
          Rules::HtmlAvoidBothDisabledAndAriaDisabled,
          Rules::HtmlBooleanAttributesNoValue,
          Rules::HtmlIframeHasTitle,
          Rules::HtmlImgRequireAlt,
          Rules::HtmlNoDuplicateAttributes,
          Rules::HtmlNoDuplicateIds,
          Rules::HtmlNoDuplicateMetaNames,
          Rules::HtmlNoEmptyAttributes,
          Rules::HtmlNoNestedLinks,
          Rules::HtmlNoTitleAttribute,
          Rules::HtmlNoUnderscoresInAttributeNames,
          Rules::HtmlNoPositiveTabIndex,
          Rules::HtmlNoSelfClosing,
          Rules::HtmlNoSpaceInTag,
          Rules::HtmlTagNameLowercase
        ].freeze
      end
      # rubocop:enable Metrics/MethodLength

      def initialize #: void
        @rules = {}
      end

      # Register a rule class in the registry.
      # @rbs rule_class: singleton(Rules::Base) | singleton(Rules::VisitorRule)
      def register(rule_class) #: void
        name = rule_class.rule_name
        @rules[name] = rule_class
      end

      # Get a rule class by its name.
      # @rbs name: String
      def get(name) #: (singleton(Rules::Base) | singleton(Rules::VisitorRule))?
        @rules[name]
      end

      # Check if a rule with the given name is registered.
      # @rbs name: String
      def registered?(name) #: bool
        @rules.key?(name)
      end

      # Get all registered rule classes.
      def all #: Array[singleton(Rules::Base) | singleton(Rules::VisitorRule)]
        @rules.values
      end

      # Get all registered rule names.
      def rule_names #: Array[String]
        @rules.keys.sort
      end

      # Number of registered rules.
      def size #: Integer
        @rules.size
      end

      # Load all built-in rules into the registry.
      def load_builtin_rules #: void
        self.class.builtin_rules.each { |rule_class| register(rule_class) }
      end

      # Load custom rules from a directory.
      # @rbs path: String -- path to directory containing rule files
      def load_custom_rules(path) #: void
        return unless File.directory?(path)

        Dir.glob(File.join(path, "*.rb")).each do |file|
          load_rule_file(file)
        end
      end

      private

      # @rbs file: String
      def load_rule_file(file) #: void
        require file
      end
    end
  end
end
