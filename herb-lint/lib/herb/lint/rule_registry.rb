# frozen_string_literal: true

module Herb
  module Lint
    # Registry for managing lint rules.
    # Provides registration, lookup, and loading of built-in and custom rules.
    # rubocop:disable Metrics/ClassLength
    class RuleRegistry
      # @rbs @rules: Hash[String, singleton(Rules::Base) | singleton(Rules::VisitorRule)]
      # @rbs @config: Herb::Config::LinterConfig?
      # @rbs @base_dir: String?

      attr_reader :config, :base_dir

      # Built-in rule classes shipped with herb-lint.
      # rubocop:disable Metrics/MethodLength
      def self.builtin_rules #: Array[singleton(Rules::Base) | singleton(Rules::VisitorRule)]
        @builtin_rules ||= [
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

      # @rbs config: Herb::Config::LinterConfig? -- configuration for rules (optional for backward compatibility)
      # @rbs base_dir: String? -- base directory for pattern matching (optional for backward compatibility)
      # @rbs builtins: bool -- when true, automatically load built-in rules
      # @rbs rules: Array[singleton(Rules::Base) | singleton(Rules::VisitorRule)]
      def initialize(config: nil, base_dir: nil, builtins: true, rules: []) #: void
        @config = config
        @base_dir = base_dir
        @rules = {}
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

      # Build instances of all registered rules.
      # Reads enabled status and severity from config for each rule.
      # If config and base_dir are set, creates pattern matchers for each rule.
      # @rbs config: Herb::Config::LinterConfig? -- optional override for config (uses @config if not provided)
      # @rbs base_dir: String? -- optional override for base_dir (uses @base_dir if not provided)
      def build_all(config: nil, base_dir: nil) #: Array[Rules::Base | Rules::VisitorRule]
        effective_config = config || @config
        effective_base_dir = base_dir || @base_dir

        raise ArgumentError, "config is required (either in initialize or build_all)" unless effective_config

        @rules.filter_map do |rule_name, rule_class|
          next unless effective_config.enabled_rule?(rule_name)

          severity = effective_config.rule_severity(rule_name)

          # Create pattern matcher if base_dir is available
          matcher = (effective_config.build_pattern_matcher(effective_base_dir, rule_name) if effective_base_dir)

          rule_class.new(severity:, matcher:)
        end
      end

      # Number of registered rules.
      def size #: Integer
        @rules.size
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
    # rubocop:enable Metrics/ClassLength
  end
end
