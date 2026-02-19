# frozen_string_literal: true

module Herb
  module Lint
    # Registry for managing lint rules.
    # Provides registration, lookup, and loading of built-in and custom rules.
    class RuleRegistry
      # @rbs @rules: Hash[String, singleton(Rules::VisitorRule) | singleton(Rules::SourceRule)]
      # @rbs @config: Herb::Config::LinterConfig

      # Built-in rule classes shipped with herb-lint.
      # rubocop:disable Metrics/MethodLength
      def self.builtin_rules #: Array[singleton(Rules::VisitorRule) | singleton(Rules::SourceRule)]
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
          Rules::Svg::TagNameCapitalization
        ].freeze
      end
      # rubocop:enable Metrics/MethodLength

      # @rbs config: Herb::Config::LinterConfig -- configuration for rules
      # @rbs builtins: bool -- when true, automatically load built-in rules
      # @rbs rules: Array[singleton(Rules::VisitorRule) | singleton(Rules::SourceRule)]
      def initialize(config:, builtins: true, rules: []) #: void
        @rules = {}
        @config = config
        load_builtin_rules if builtins
        rules.each { register(_1) }
      end

      # Register a rule class in the registry.
      # @rbs rule_class: singleton(Rules::VisitorRule) | singleton(Rules::SourceRule)
      def register(rule_class) #: void
        name = rule_class.rule_name
        @rules[name] = rule_class
      end

      # Get a rule class by its name.
      # @rbs name: String
      def get(name) #: (singleton(Rules::VisitorRule) | singleton(Rules::SourceRule))?
        @rules[name]
      end

      # Get all registered rule names.
      def rule_names #: Array[String]
        @rules.keys.sort
      end

      # Build instances of all registered rules.
      # Reads enabled status and severity from config for each rule.
      # Creates a PatternMatcher for each rule based on its include/exclude/only configuration.
      def build_all #: Array[Rules::VisitorRule | Rules::SourceRule]
        @rules.filter_map do |rule_name, rule_class|
          # Check if rule is enabled, using the rule's default enabled state
          default_enabled = rule_class.enabled_by_default?
          next unless @config.enabled_rule?(rule_name, default: default_enabled)

          matcher = @config.build_pattern_matcher(rule_name)
          rule_class.new(severity: @config.rule_severity(rule_name), matcher:)
        end
      end

      # Load and register custom rules from the given require names.
      # Each name is passed to Kernel#require. Any newly defined rule classes
      # are automatically discovered via ObjectSpace and registered.
      # @rbs names: Array[String] -- require names (gem names or file paths)
      def load_custom_rules(names) #: void
        return if names.empty?

        before = all_rule_subclasses
        names.each { require _1 }
        (all_rule_subclasses - before).each { register(_1) }
      end

      private

      # Returns all currently loaded rule subclasses via ObjectSpace.
      # Used to detect newly defined rules after requiring custom rule files.
      def all_rule_subclasses #: Array[singleton(Rules::VisitorRule) | singleton(Rules::SourceRule)]
        ObjectSpace.each_object(Class)
                   .select { _1 < Rules::VisitorRule || _1 < Rules::SourceRule }
                   .to_a
      end

      # Load all built-in rules into the registry.
      def load_builtin_rules #: void
        self.class.builtin_rules.each { register(_1) }
      end
    end
  end
end
