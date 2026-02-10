# frozen_string_literal: true

module Herb
  module Lint
    # Registry for managing lint rules.
    # Provides registration, lookup, and loading of built-in and custom rules.
    class RuleRegistry
      # @rbs @rules: Hash[String, singleton(Rules::Base) | singleton(Rules::VisitorRule)]
      # @rbs @config: Herb::Config::LinterConfig

      # Built-in rule classes shipped with herb-lint.
      # rubocop:disable Metrics/MethodLength
      def self.builtin_rules #: Array[singleton(Rules::Base) | singleton(Rules::VisitorRule)]
        [
          Rules::Erb::CommentSyntax,
          Rules::Erb::NoCaseNodeChildren,
          Rules::Erb::NoEmptyTags,
          Rules::Erb::NoExtraNewline,
          Rules::Erb::NoExtraWhitespaceInsideTags,
          Rules::Erb::NoOutputControlFlow,
          Rules::Erb::NoSilentTagInAttributeName,
          Rules::Erb::PreferImageTagHelper,
          Rules::Erb::RequireTrailingNewline,
          Rules::Erb::RequireWhitespaceInsideTags,
          Rules::Erb::RightTrim,
          Rules::Erb::StrictLocalsCommentSyntax,
          Rules::Erb::StrictLocalsRequired,
          Rules::HerbDirective::DisableCommentMalformed,
          Rules::HerbDirective::DisableCommentMissingRules,
          Rules::HerbDirective::DisableCommentNoDuplicateRules,
          Rules::HerbDirective::DisableCommentNoRedundantAll,
          Rules::HerbDirective::DisableCommentValidRuleName,
          Rules::Html::AnchorRequireHref,
          Rules::Html::AriaAttributeMustBeValid,
          Rules::Html::AriaLabelIsWellFormatted,
          Rules::Html::AriaLevelMustBeValid,
          Rules::Html::AriaRoleHeadingRequiresLevel,
          Rules::Html::AriaRoleMustBeValid,
          Rules::Html::AttributeDoubleQuotes,
          Rules::Html::AttributeEqualsSpacing,
          Rules::Html::AttributeValuesRequireQuotes,
          Rules::Html::AvoidBothDisabledAndAriaDisabled,
          Rules::Html::BodyOnlyElements,
          Rules::Html::BooleanAttributesNoValue,
          Rules::Html::HeadOnlyElements,
          Rules::Html::IframeHasTitle,
          Rules::Html::ImgRequireAlt,
          Rules::Html::InputRequireAutocomplete,
          Rules::Html::NavigationHasLabel,
          Rules::Html::NoAriaHiddenOnFocusable,
          Rules::Html::NoBlockInsideInline,
          Rules::Html::NoDuplicateAttributes,
          Rules::Html::NoDuplicateIds,
          Rules::Html::NoDuplicateMetaNames,
          Rules::Html::NoEmptyAttributes,
          Rules::Html::NoEmptyHeadings,
          Rules::Html::NoNestedLinks,
          Rules::Html::NoPositiveTabIndex,
          Rules::Html::NoSelfClosing,
          Rules::Html::NoSpaceInTag,
          Rules::Html::NoTitleAttribute,
          Rules::Html::NoUnderscoresInAttributeNames,
          Rules::Html::TagNameLowercase,
          Rules::Parser::NoErrors,
          Rules::Svg::TagNameCapitalization
        ].freeze
      end
      # rubocop:enable Metrics/MethodLength

      # @rbs config: Herb::Config::LinterConfig -- configuration for rules
      # @rbs builtins: bool -- when true, automatically load built-in rules
      # @rbs rules: Array[singleton(Rules::Base) | singleton(Rules::VisitorRule)]
      def initialize(config:, builtins: true, rules: []) #: void
        @rules = {}
        @config = config
        load_builtin_rules if builtins
        rules.each { register(_1) }
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

      # Get all registered rule names.
      def rule_names #: Array[String]
        @rules.keys.sort
      end

      # Build instances of all registered rules.
      # Reads enabled status and severity from config for each rule.
      # Creates a PatternMatcher for each rule based on its include/exclude/only configuration.
      def build_all #: Array[Rules::Base | Rules::VisitorRule]
        @rules.filter_map do |rule_name, rule_class|
          next unless @config.enabled_rule?(rule_name)

          matcher = @config.build_pattern_matcher(rule_name)
          rule_class.new(severity: @config.rule_severity(rule_name), matcher:)
        end
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

      # Load all built-in rules into the registry.
      def load_builtin_rules #: void
        self.class.builtin_rules.each { register(_1) }
      end

      # @rbs file: String
      def load_rule_file(file) #: void
        require file
      end
    end
  end
end
