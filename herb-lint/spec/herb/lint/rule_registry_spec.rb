# frozen_string_literal: true

RSpec.describe Herb::Lint::RuleRegistry do
  subject(:registry) { described_class.new }

  let(:test_rule_class) do
    Class.new(Herb::Lint::Rules::Base) do
      def self.rule_name = "test-rule"
    end
  end

  let(:another_rule_class) do
    Class.new(Herb::Lint::Rules::Base) do
      def self.rule_name = "another-rule"
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

  describe "#registered?" do
    context "when the rule is registered" do
      before { registry.register(test_rule_class) }

      it "returns true" do
        expect(registry.registered?("test-rule")).to be true
      end
    end

    context "when the rule is not registered" do
      it "returns false" do
        expect(registry.registered?("nonexistent-rule")).to be false
      end
    end
  end

  describe "#all" do
    context "when no rules are registered" do
      it "returns an empty array" do
        expect(registry.all).to eq([])
      end
    end

    context "when rules are registered" do
      before do
        registry.register(test_rule_class)
        registry.register(another_rule_class)
      end

      it "returns all registered rule classes" do
        expect(registry.all).to contain_exactly(test_rule_class, another_rule_class)
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

  describe "#size" do
    context "when no rules are registered" do
      it "returns 0" do
        expect(registry.size).to eq(0)
      end
    end

    context "when rules are registered" do
      before do
        registry.register(test_rule_class)
        registry.register(another_rule_class)
      end

      it "returns the count of registered rules" do
        expect(registry.size).to eq(2)
      end
    end
  end

  describe "#load_builtin_rules" do
    it "registers all built-in rules" do
      registry.load_builtin_rules

      expect(registry.size).to eq(7)
      expect(registry.get("alt-text")).to eq(Herb::Lint::Rules::A11y::AltText)
      expect(registry.get("html/attribute-quotes")).to eq(Herb::Lint::Rules::Html::AttributeQuotes)
      expect(registry.get("html/lowercase-attributes")).to eq(Herb::Lint::Rules::Html::LowercaseAttributes)
      expect(registry.get("html/lowercase-tags")).to eq(Herb::Lint::Rules::Html::LowercaseTags)
      expect(registry.get("html/no-duplicate-attributes")).to eq(Herb::Lint::Rules::Html::NoDuplicateAttributes)
      expect(registry.get("html/no-duplicate-id")).to eq(Herb::Lint::Rules::Html::NoDuplicateId)
      expect(registry.get("html/no-positive-tabindex")).to eq(Herb::Lint::Rules::Html::NoPositiveTabindex)
    end

    it "allows loading built-in rules multiple times without duplicates" do
      registry.load_builtin_rules
      registry.load_builtin_rules

      expect(registry.size).to eq(7)
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
        expect(registry.size).to eq(0)
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
