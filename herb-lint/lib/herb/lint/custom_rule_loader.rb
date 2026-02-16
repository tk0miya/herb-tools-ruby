# frozen_string_literal: true

# rbs_inline: enabled

module Herb
  module Lint
    # Loads custom linter rules from user's project.
    #
    # Auto-discovers rule files in `.herb/rules/` by default
    # and dynamically loads them into the RuleRegistry.
    #
    # Based on TypeScript reference: `javascript/packages/linter/src/custom-rule-loader.ts`
    class CustomRuleLoader # rubocop:disable Metrics/ClassLength
      DEFAULT_PATTERNS = [".herb/rules/**/*.rb"].freeze

      attr_reader :base_dir, :patterns, :registry, :silent

      # @rbs registry: RuleRegistry
      # @rbs base_dir: String
      # @rbs patterns: Array[String]
      # @rbs silent: bool
      def initialize(registry, base_dir: Dir.pwd, patterns: DEFAULT_PATTERNS, silent: false) #: void
        @registry = registry
        @base_dir = base_dir
        @patterns = patterns
        @silent = silent
      end

      # Discover custom rule files in the project.
      def discover_rule_files #: Array[String]
        all_files = []

        @patterns.each do |pattern|
          files = Dir.glob(File.join(@base_dir, pattern))
          all_files.concat(files)
        rescue StandardError => e
          warn "Warning: Failed to search pattern \"#{pattern}\": #{e.message}" unless @silent
        end

        all_files.uniq
      end

      # Load a single rule file.
      #
      # @rbs file_path: String
      def load_rule_file(file_path) #: Array[singleton(Rules::VisitorRule) | singleton(Rules::SourceRule)]
        # Capture constant names before loading (not the classes themselves)
        constants_before = scan_constant_names

        load File.expand_path(file_path)

        # Find newly defined rule classes
        constants_after = scan_constant_names
        new_constant_names = constants_after - constants_before

        # Convert constant names to actual rule classes
        newly_defined_rules = []
        new_constant_names.each do |const_path|
          const = Object.const_get(const_path)
          newly_defined_rules << const if valid_rule_class?(const)
        rescue StandardError
          # Skip constants that can't be retrieved or aren't valid rules
          next
        end

        newly_defined_rules
      rescue LoadError, SyntaxError, StandardError => e
        warn "Warning: Failed to load rule file \"#{file_path}\": #{e.message}" unless @silent
        []
      end

      # Load all custom rules from the project.
      def load_rules #: Array[singleton(Rules::VisitorRule) | singleton(Rules::SourceRule)]
        rule_files = discover_rule_files
        return [] if rule_files.empty?

        all_rules = []

        rule_files.each do |file_path|
          rules = load_rule_file(file_path)
          all_rules.concat(rules)
        end

        all_rules
      end

      # Load all custom rules and return detailed information.
      def load_rules_with_info #: LoadResult
        rule_files = discover_rule_files
        return empty_load_result if rule_files.empty?

        all_rules = []
        rule_info = []
        duplicate_warnings = []
        seen_names = {}

        rule_files.each do |file_path|
          process_rule_file(file_path, all_rules, rule_info, duplicate_warnings, seen_names)
        end

        LoadResult.new(rules: all_rules, rule_info:, duplicate_warnings:)
      end

      # Check if custom rules exist in a project.
      #
      # @rbs base_dir: String
      def self.has_custom_rules?(base_dir: Dir.pwd) #: bool # rubocop:disable Naming/PredicatePrefix
        config = Herb::Config::LinterConfig.new({})
        registry = RuleRegistry.new(config:, builtins: false)
        loader = new(registry, base_dir:, silent: true)
        files = loader.discover_rule_files
        !files.empty?
      end

      private

      # Return an empty LoadResult.
      def empty_load_result #: LoadResult
        LoadResult.new(rules: [], rule_info: [], duplicate_warnings: [])
      end

      # Process a single rule file and update collections.
      #
      # @rbs file_path: String
      # @rbs all_rules: Array[singleton(Rules::VisitorRule) | singleton(Rules::SourceRule)]
      # @rbs rule_info: Array[RuleInfo]
      # @rbs duplicate_warnings: Array[String]
      # @rbs seen_names: Hash[String, String]
      def process_rule_file(file_path, all_rules, rule_info, duplicate_warnings, seen_names) #: void
        rules = load_rule_file(file_path)

        rules.each do |rule_class|
          process_rule_class(rule_class, file_path, all_rules, rule_info, duplicate_warnings, seen_names)
        end
      end

      # Process a single rule class and update collections.
      #
      # @rbs rule_class: singleton(Rules::VisitorRule) | singleton(Rules::SourceRule)
      # @rbs file_path: String
      # @rbs all_rules: Array[singleton(Rules::VisitorRule) | singleton(Rules::SourceRule)]
      # @rbs rule_info: Array[RuleInfo]
      # @rbs duplicate_warnings: Array[String]
      # @rbs seen_names: Hash[String, String]
      # rubocop:disable Metrics/ParameterLists
      def process_rule_class(rule_class, file_path, all_rules, rule_info, duplicate_warnings, seen_names) #: void
        # rubocop:enable Metrics/ParameterLists
        rule_name = rule_class.rule_name

        if seen_names.key?(rule_name)
          add_duplicate_warning(rule_name, seen_names[rule_name], file_path, duplicate_warnings)
        else
          seen_names[rule_name] = file_path
        end

        all_rules << rule_class
        rule_info << RuleInfo.new(name: rule_name, path: file_path)
      end

      # Add a duplicate rule warning message.
      #
      # @rbs rule_name: String
      # @rbs first_path: String
      # @rbs second_path: String
      # @rbs warnings: Array[String]
      def add_duplicate_warning(rule_name, first_path, second_path, warnings) #: void
        message = "Custom rule \"#{rule_name}\" is defined in multiple files: " \
                  "\"#{first_path}\" and \"#{second_path}\". The later one will be used."
        warnings << message
      end

      # Scan all constant names in Herb::Lint::Rules module.
      # Returns fully qualified constant names as strings.
      def scan_constant_names #: Array[String]
        names = []

        # Check if Herb::Lint::Rules module exists and has constants
        return names unless defined?(Herb::Lint::Rules)

        # Recursively scan all submodules in Herb::Lint::Rules
        scan_module_for_constant_names(Herb::Lint::Rules, "Herb::Lint::Rules", names)

        names
      end

      # Recursively scan a module for constant names.
      #
      # @rbs mod: Module
      # @rbs prefix: String
      # @rbs names: Array[String]
      def scan_module_for_constant_names(mod, prefix, names) #: void
        mod.constants(false).each do |const_name|
          full_name = "#{prefix}::#{const_name}"
          names << full_name

          begin
            const = mod.const_get(const_name)
            if const.is_a?(Module) && const != mod
              # Recursively scan submodules
              scan_module_for_constant_names(const, full_name, names)
            end
          rescue StandardError
            # Skip constants that raise errors (e.g., autoloaded constants)
            next
          end
        end
      end

      # Scan all constants for valid rule classes.
      # This method is used to detect newly loaded rules after require.
      def scan_constants_for_rules #: Array[singleton(Rules::VisitorRule) | singleton(Rules::SourceRule)]
        rules = []

        # Check if Herb::Lint::Rules module exists and has constants
        return rules unless defined?(Herb::Lint::Rules)

        # Recursively scan all submodules in Herb::Lint::Rules
        scan_module_for_rules(Herb::Lint::Rules, rules)

        rules
      end

      # Recursively scan a module for rule classes.
      #
      # @rbs mod: Module
      # @rbs rules: Array[singleton(Rules::VisitorRule) | singleton(Rules::SourceRule)]
      def scan_module_for_rules(mod, rules) #: void
        mod.constants(false).each do |const_name|
          const = mod.const_get(const_name)

          if const.is_a?(Module) && const != mod
            # Recursively scan submodules
            scan_module_for_rules(const, rules)
          elsif valid_rule_class?(const)
            rules << const
          end
        rescue StandardError
          # Skip constants that raise errors (e.g., autoloaded constants)
          next
        end
      end

      # Type guard to check if a value is a valid rule class.
      #
      # @rbs value: untyped
      def valid_rule_class?(value) #: bool
        return false unless value.is_a?(Class)
        return false unless subclass_of_rule?(value)
        return false unless required_methods?(value)

        true
      rescue StandardError
        false
      end

      # Check if a class is a subclass of VisitorRule or SourceRule.
      #
      # @rbs value: Class
      def subclass_of_rule?(value) #: bool
        value < Rules::VisitorRule || value < Rules::SourceRule
      end

      # Check if a class has required rule methods.
      #
      # @rbs value: Class
      def required_methods?(value) #: bool
        value.respond_to?(:rule_name) &&
          value.respond_to?(:description) &&
          value.rule_name.is_a?(String) &&
          !value.rule_name.empty?
      end
    end

    # Result of loading custom rules with detailed information
    LoadResult = Data.define(:rules, :rule_info, :duplicate_warnings)

    # Information about a loaded custom rule
    RuleInfo = Data.define(:name, :path)
  end
end
