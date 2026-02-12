# frozen_string_literal: true

RSpec.describe Herb::Lint::RuleRegistry do
  subject(:registry) { described_class.new(builtins: false, config:) }

  let(:config_hash) { {} }
  let(:config) { Herb::Config::LinterConfig.new(config_hash) }
  let(:test_rule_class) do
    Class.new(Herb::Lint::Rules::VisitorRule) do
      def self.rule_name = "test-rule"
      def self.description = "Test rule"
      def self.safe_autofixable? = false
      def self.unsafe_autofixable? = false
    end
  end
  let(:another_rule_class) do
    Class.new(Herb::Lint::Rules::VisitorRule) do
      def self.rule_name = "another-rule"
      def self.description = "Another test rule"
      def self.safe_autofixable? = false
      def self.unsafe_autofixable? = false
    end
  end
  let(:disabled_by_default_rule_class) do
    Class.new(Herb::Lint::Rules::VisitorRule) do
      def self.rule_name = "disabled-by-default-rule"
      def self.description = "Rule disabled by default"
      def self.safe_autofixable? = false
      def self.unsafe_autofixable? = false
      def self.enabled_by_default? = false
    end
  end

  describe "#initialize" do
    context "with builtins: true (default)" do
      subject { described_class.new(config:) }

      it "automatically registers all built-in rules" do
        expect(subject.rule_names.size).to eq(described_class.builtin_rules.size)

        described_class.builtin_rules.each do |rule_class|
          expect(subject.get(rule_class.rule_name)).to eq(rule_class)
        end
      end
    end

    context "with builtins: false" do
      subject { described_class.new(builtins: false, config:) }

      it "starts with an empty registry" do
        expect(subject.rule_names.size).to eq(0)
      end
    end

    context "with rules argument" do
      it "registers all provided rules" do
        registry = described_class.new(builtins: false, rules: [test_rule_class, another_rule_class], config:)
        expect(registry.rule_names.size).to eq(2)
        expect(registry.get("test-rule")).to eq(test_rule_class)
        expect(registry.get("another-rule")).to eq(another_rule_class)
      end
    end

    context "with both builtins and rules" do
      it "registers both built-in and provided rules" do
        registry = described_class.new(builtins: true, rules: [test_rule_class], config:)
        expect(registry.rule_names.size).to eq(described_class.builtin_rules.size + 1)
        expect(registry.get("test-rule")).to eq(test_rule_class)
      end
    end
  end

  describe "#register" do
    it "registers a rule class by its rule_name" do
      registry.register(test_rule_class)
      expect(registry.get("test-rule")).to eq(test_rule_class)
    end
  end

  describe "#get" do
    context "when the rule is registered" do
      before { registry.register(test_rule_class) }

      it "returns the rule class" do
        expect(registry.get("test-rule")).to eq(test_rule_class)
      end
    end

    context "when the rule is not registered" do
      it "returns nil" do
        expect(registry.get("nonexistent-rule")).to be_nil
      end
    end
  end

  describe "#rule_names" do
    context "when no rules are registered" do
      it "returns an empty array" do
        expect(registry.rule_names).to eq([])
      end
    end

    context "when rules are registered" do
      before do
        registry.register(test_rule_class)
        registry.register(another_rule_class)
      end

      it "returns sorted rule names" do
        expect(registry.rule_names).to eq(%w[another-rule test-rule])
      end
    end
  end

  describe "#build_all" do
    before do
      registry.register(test_rule_class)
      registry.register(another_rule_class)
    end

    context "with empty config" do
      it "builds instances of all registered rules" do
        rules = registry.build_all

        expect(rules.size).to eq(2)
        expect(rules[0]).to be_a(test_rule_class)
        expect(rules[1]).to be_a(another_rule_class)
      end
    end

    context "with config that disables a rule" do
      let(:config_hash) do
        {
          "linter" => {
            "rules" => {
              "test-rule" => {
                "enabled" => false
              }
            }
          }
        }
      end

      it "builds instances of all rules except disabled ones" do
        rules = registry.build_all

        expect(rules.size).to eq(1)
        expect(rules[0]).to be_a(another_rule_class)
      end
    end

    context "with config that disables multiple rules" do
      let(:config_hash) do
        {
          "linter" => {
            "rules" => {
              "test-rule" => {
                "enabled" => false
              },
              "another-rule" => {
                "enabled" => false
              }
            }
          }
        }
      end

      it "excludes all disabled rules" do
        rules = registry.build_all

        expect(rules).to be_empty
      end
    end

    context "with config that has no disabled rules" do
      it "builds all rules" do
        rules = registry.build_all

        expect(rules.size).to eq(2)
      end
    end

    context "when no rules are registered" do
      subject(:empty_registry) { described_class.new(builtins: false, config:) }

      it "returns an empty array" do
        rules = empty_registry.build_all

        expect(rules).to eq([])
      end
    end

    context "with config parameter" do
      let(:config_hash) do
        {
          "linter" => {
            "rules" => {
              "test-rule" => {
                "severity" => "warning"
              }
            }
          }
        }
      end

      it "passes severity from config to rules" do
        rules = registry.build_all

        expect(rules.size).to eq(2)
        expect(rules[0].severity).to eq("warning")
        expect(rules[1].severity).to eq("warning") # default_severity from rule class
      end
    end

    context "with config that disables and configures rules" do
      let(:config_hash) do
        {
          "linter" => {
            "rules" => {
              "test-rule" => {
                "enabled" => false
              },
              "another-rule" => {
                "severity" => "error"
              }
            }
          }
        }
      end

      it "applies config only to enabled rules" do
        rules = registry.build_all

        expect(rules.size).to eq(1)
        expect(rules[0]).to be_a(another_rule_class)
        expect(rules[0].severity).to eq("error")
      end
    end

    context "with rule that is disabled by default" do
      before do
        registry.register(disabled_by_default_rule_class)
      end

      context "when no config is specified" do
        it "does not build the disabled-by-default rule" do
          rules = registry.build_all

          expect(rules.size).to eq(2)
          expect(rules.map(&:class)).not_to include(disabled_by_default_rule_class)
        end
      end

      context "when explicitly enabled in config" do
        let(:config_hash) do
          {
            "linter" => {
              "rules" => {
                "disabled-by-default-rule" => {
                  "enabled" => true
                }
              }
            }
          }
        end

        it "builds the disabled-by-default rule" do
          rules = registry.build_all

          expect(rules.size).to eq(3)
          expect(rules.map(&:class)).to include(disabled_by_default_rule_class)
        end
      end

      context "when explicitly disabled in config" do
        let(:config_hash) do
          {
            "linter" => {
              "rules" => {
                "disabled-by-default-rule" => {
                  "enabled" => false
                }
              }
            }
          }
        end

        it "does not build the disabled-by-default rule" do
          rules = registry.build_all

          expect(rules.size).to eq(2)
          expect(rules.map(&:class)).not_to include(disabled_by_default_rule_class)
        end
      end
    end
  end

  describe "#load_custom_rules" do
    let(:custom_rules_dir) { File.join(Dir.tmpdir, "herb_test_rules_#{Process.pid}") }

    before do
      FileUtils.mkdir_p(custom_rules_dir)
    end

    after do
      FileUtils.rm_rf(custom_rules_dir)
    end

    context "when directory does not exist" do
      it "does not raise an error" do
        expect { registry.load_custom_rules("/nonexistent/path") }.not_to raise_error
      end
    end

    context "when directory is empty" do
      it "does not load any rules" do
        registry.load_custom_rules(custom_rules_dir)
        expect(registry.rule_names.size).to eq(0)
      end
    end

    context "when directory contains rule files" do
      before do
        File.write(File.join(custom_rules_dir, "custom_rule.rb"), <<~RUBY)
          # Custom rule file placeholder
        RUBY
      end

      it "loads the rule files without error" do
        expect { registry.load_custom_rules(custom_rules_dir) }.not_to raise_error
      end
    end
  end
end
