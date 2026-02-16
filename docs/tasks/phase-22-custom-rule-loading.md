# Phase 22: Custom Rule Loading

**Status:** 📋 Ready to implement

**Background:** TypeScript reference has full Custom Rule Loading support (`CustomRuleLoader` class). Ruby version has basic `RuleRegistry#load_custom_rules` but lacks auto-registration, validation, and duplicate detection.

## Overview

Implement complete custom rule loading to match TypeScript reference implementation.

| Feature | TypeScript | Ruby (Current) | Status |
|---------|-----------|----------------|--------|
| Discover rule files | ✅ `.herb/rules/**/*.mjs` | ⚠️ `path/*.rb` only | Needs glob support |
| Dynamic loading | ✅ Dynamic import + cache | ✅ `require` | ✅ Done |
| Auto-registration | ✅ Automatic | ❌ Manual | **Need to implement** |
| Class validation | ✅ Type checking | ❌ No validation | **Need to implement** |
| Duplicate detection | ✅ Warnings | ❌ Silent override | **Need to implement** |
| Error handling | ✅ Graceful | ⚠️ Basic | Needs improvement |

## Prerequisites

- herb-lint gem with RuleRegistry
- herb/lint/rules/base.rb (rule interface)

---

## 📋 Task Checklist

- [ ] Task 22.1: Implement Custom Rule Discovery
- [ ] Task 22.2: Integrate CustomRuleLoader with Runner
- [ ] Task 22.3: Add CLI Option for Custom Rules
- [ ] Task 22.4: Documentation

**Progress: 0/4 tasks completed**

---

## Part A: Enhanced Discovery

### Task 22.1: Implement Custom Rule Discovery

**Location:** `herb-lint/lib/herb/lint/custom_rule_loader.rb`

**Goal:** Create dedicated CustomRuleLoader class matching TypeScript implementation.

**Create new file:**

```ruby
# rbs_inline: enabled

module Herb
  module Lint
    # Loads custom linter rules from user's project.
    #
    # Auto-discovers rule files in `.herb/rules/` by default
    # and dynamically loads them into the RuleRegistry.
    #
    # Based on TypeScript reference: `javascript/packages/linter/src/custom-rule-loader.ts`
    #
    # @rbs!
    #   class CustomRuleLoader
    #     attr_reader base_dir: String
    #     attr_reader patterns: Array[String]
    #     attr_reader registry: RuleRegistry
    #     attr_reader silent: bool
    #
    #     def initialize: (
    #       RuleRegistry registry,
    #       ?base_dir: String,
    #       ?patterns: Array[String],
    #       ?silent: bool
    #     ) -> void
    #
    #     def discover_rule_files: () -> Array[String]
    #     def load_rule_file: (String file_path) -> Array[singleton(Rules::Base)]
    #     def load_rules: () -> Array[singleton(Rules::Base)]
    #     def load_rules_with_info: () -> LoadResult
    #     def self.has_custom_rules?: (?base_dir: String) -> bool
    #
    #     private
    #     def valid_rule_class?: (untyped value) -> bool
    #   end
    #
    #   class LoadResult < Data
    #     attr_reader rules: Array[singleton(Rules::Base)]
    #     attr_reader rule_info: Array[RuleInfo]
    #     attr_reader duplicate_warnings: Array[String]
    #   end
    #
    #   class RuleInfo < Data
    #     attr_reader name: String
    #     attr_reader path: String
    #   end
    class CustomRuleLoader
      DEFAULT_PATTERNS = [".herb/rules/**/*.rb"].freeze

      attr_reader :base_dir, :patterns, :registry, :silent

      # @rbs registry: RuleRegistry
      # @rbs base_dir: String
      # @rbs patterns: Array[String]
      # @rbs silent: bool
      def initialize(registry, base_dir: Dir.pwd, patterns: DEFAULT_PATTERNS, silent: false)
        @registry = registry
        @base_dir = base_dir
        @patterns = patterns
        @silent = silent
      end

      # Discover custom rule files in the project.
      #
      # @rbs return: Array[String]
      def discover_rule_files
        all_files = []

        @patterns.each do |pattern|
          begin
            files = Dir.glob(File.join(@base_dir, pattern))
            all_files.concat(files)
          rescue StandardError => e
            warn "Warning: Failed to search pattern \"#{pattern}\": #{e.message}" unless @silent
          end
        end

        all_files.uniq
      end

      # Load a single rule file.
      #
      # @rbs file_path: String
      # @rbs return: Array[singleton(Rules::Base)]
      def load_rule_file(file_path)
        require File.expand_path(file_path)

        # Find newly defined rule classes
        # This is Ruby-specific - we scan Herb::Lint::Rules module for new classes
        rules = []

        Object.constants.each do |const_name|
          const = Object.const_get(const_name)
          next unless const.is_a?(Module)

          # Check Herb::Lint::Rules namespace
          if const == Herb::Lint::Rules
            const.constants.each do |rule_const_name|
              rule_class = const.const_get(rule_const_name)
              if valid_rule_class?(rule_class)
                rules << rule_class
              end
            end
          end
        end

        rules
      rescue LoadError, StandardError => e
        warn "Warning: Failed to load rule file \"#{file_path}\": #{e.message}" unless @silent
        []
      end

      # Load all custom rules from the project.
      #
      # @rbs return: Array[singleton(Rules::Base)]
      def load_rules
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
      #
      # @rbs return: LoadResult
      def load_rules_with_info
        rule_files = discover_rule_files
        return LoadResult.new(rules: [], rule_info: [], duplicate_warnings: []) if rule_files.empty?

        all_rules = []
        rule_info = []
        duplicate_warnings = []
        seen_names = {}

        rule_files.each do |file_path|
          rules = load_rule_file(file_path)

          rules.each do |rule_class|
            rule_name = rule_class.rule_name

            if seen_names.key?(rule_name)
              first_path = seen_names[rule_name]
              duplicate_warnings << "Custom rule \"#{rule_name}\" is defined in multiple files: \"#{first_path}\" and \"#{file_path}\". The later one will be used."
            else
              seen_names[rule_name] = file_path
            end

            all_rules << rule_class
            rule_info << RuleInfo.new(name: rule_name, path: file_path)
          end
        end

        LoadResult.new(
          rules: all_rules,
          rule_info: rule_info,
          duplicate_warnings: duplicate_warnings
        )
      end

      # Check if custom rules exist in a project.
      #
      # @rbs base_dir: String
      # @rbs return: bool
      def self.has_custom_rules?(base_dir: Dir.pwd)
        loader = new(RuleRegistry.new, base_dir: base_dir, silent: true)
        files = loader.discover_rule_files
        !files.empty?
      end

      private

      # Type guard to check if a value is a valid rule class.
      #
      # @rbs value: untyped
      # @rbs return: bool
      def valid_rule_class?(value)
        return false unless value.is_a?(Class)
        return false unless value < Rules::Base

        # Check if required class methods are implemented
        value.respond_to?(:rule_name) &&
          value.respond_to?(:description) &&
          value.rule_name.is_a?(String) &&
          !value.rule_name.empty?
      rescue StandardError
        false
      end
    end

    # Result of loading custom rules with detailed information
    class LoadResult < Data.define(:rules, :rule_info, :duplicate_warnings)
    end

    # Information about a loaded custom rule
    class RuleInfo < Data.define(:name, :path)
    end
  end
end
```

**Test Cases:**

```ruby
# herb-lint/spec/herb/lint/custom_rule_loader_spec.rb
RSpec.describe Herb::Lint::CustomRuleLoader do
  let(:registry) { Herb::Lint::RuleRegistry.new }
  let(:loader) { described_class.new(registry, base_dir: base_dir) }

  describe "#discover_rule_files" do
    context "with custom rules directory" do
      let(:base_dir) { "/tmp/test_project" }

      before do
        FileUtils.mkdir_p(File.join(base_dir, ".herb/rules"))
        FileUtils.touch(File.join(base_dir, ".herb/rules/my_rule.rb"))
        FileUtils.touch(File.join(base_dir, ".herb/rules/another_rule.rb"))
      end

      after do
        FileUtils.rm_rf(base_dir)
      end

      it "discovers rule files" do
        files = loader.discover_rule_files
        expect(files).to include(
          end_with(".herb/rules/my_rule.rb"),
          end_with(".herb/rules/another_rule.rb")
        )
      end
    end

    context "without custom rules directory" do
      let(:base_dir) { "/tmp/empty_project" }

      it "returns empty array" do
        files = loader.discover_rule_files
        expect(files).to be_empty
      end
    end
  end

  describe "#load_rules_with_info" do
    # Test with actual rule file creation
    # This requires creating temporary rule files
    pending "requires filesystem setup"
  end

  describe ".has_custom_rules?" do
    context "with custom rules" do
      let(:base_dir) { "/tmp/project_with_rules" }

      before do
        FileUtils.mkdir_p(File.join(base_dir, ".herb/rules"))
        FileUtils.touch(File.join(base_dir, ".herb/rules/custom.rb"))
      end

      after do
        FileUtils.rm_rf(base_dir)
      end

      it "returns true" do
        expect(described_class.has_custom_rules?(base_dir: base_dir)).to be true
      end
    end

    context "without custom rules" do
      let(:base_dir) { "/tmp/project_without_rules" }

      it "returns false" do
        expect(described_class.has_custom_rules?(base_dir: base_dir)).to be false
      end
    end
  end
end
```

**Verification:**
- `cd herb-lint && ./bin/rspec spec/herb/lint/custom_rule_loader_spec.rb`

---

### Task 22.2: Integrate CustomRuleLoader with Runner

**Location:** `herb-lint/lib/herb/lint/runner.rb`

**Goal:** Use CustomRuleLoader in Runner to load and register custom rules.

**Implementation:**

```ruby
# In Runner#initialize or #run
def load_custom_rules
  return unless should_load_custom_rules?

  loader = CustomRuleLoader.new(
    @registry,
    base_dir: @config.project_path,
    silent: false
  )

  result = loader.load_rules_with_info

  # Display duplicate warnings
  result.duplicate_warnings.each do |warning|
    warn "Warning: #{warning}"
  end

  # Register loaded rules
  result.rules.each do |rule_class|
    @registry.register(rule_class)
  end

  # Optional: display loaded rules in verbose mode
  if @options[:verbose]
    result.rule_info.each do |info|
      puts "Loaded custom rule: #{info.name} from #{info.path}"
    end
  end
end

private

def should_load_custom_rules?
  # Load custom rules by default, unless disabled
  !@options[:no_custom_rules]
end
```

**Test Cases:**

```ruby
describe "#run" do
  context "with custom rules" do
    it "loads and registers custom rules" do
      # Test requires actual custom rule files
      pending "integration test"
    end

    it "displays duplicate warnings" do
      pending "integration test"
    end
  end
end
```

---

### Task 22.3: Add CLI Option for Custom Rules

**Location:** `herb-lint/lib/herb/lint/cli.rb`

**Goal:** Add `--no-custom-rules` option to disable custom rule loading.

**Implementation:**

```ruby
opts.on("--no-custom-rules", "Do not load custom rules from .herb/rules/") do
  options[:no_custom_rules] = true
end
```

**Test:**
```bash
herb-lint --no-custom-rules app/views
```

---

### Task 22.4: Documentation

**Location:** `herb-lint/README.md`

**Goal:** Document custom rule loading feature.

**Add section:**

```markdown
## Custom Rules

You can define custom linter rules for project-specific requirements.

### Creating Custom Rules

1. Create `.herb/rules/` directory in your project root
2. Define rule classes extending `Herb::Lint::Rules::Base`

Example:

```ruby
# .herb/rules/no_inline_scripts.rb
module Herb
  module Lint
    module Rules
      class NoInlineScripts < Base
        def self.rule_name = "custom-no-inline-scripts"
        def self.description = "Disallow inline <script> tags"

        def check(document, context)
          offenses = []

          document.descendants.each do |node|
            if node.type == :html_element && node.tag_name == "script"
              offenses << offense(
                node: node,
                message: "Inline scripts are not allowed"
              )
            end
          end

          offenses
        end
      end
    end
  end
end
```

3. Custom rules are automatically discovered and loaded
4. Configure in `.herb.yml`:

```yaml
linter:
  rules:
    custom-no-inline-scripts:
      severity: error
```

### Disabling Custom Rules

```bash
herb-lint --no-custom-rules
```
```

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 22.1 | CustomRuleLoader class | `custom_rule_loader.rb` |
| 22.2 | Integration with Runner | `runner.rb` |
| 22.3 | CLI option | `cli.rb` |
| 22.4 | Documentation | `README.md` |

**Total: 4 tasks**

## Reference

- TypeScript: `javascript/packages/linter/src/custom-rule-loader.ts`
- Design: `docs/design/herb-lint-design.md` - CustomRuleLoader section
