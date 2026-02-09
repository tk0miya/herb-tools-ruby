# frozen_string_literal: true

RSpec.describe Herb::Lint::RuleRegistry do
  subject(:registry) { described_class.new(builtins: false) }

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

  describe "#initialize" do
    context "with builtins: true (default)" do
      subject { described_class.new }

      it "automatically registers all built-in rules" do
        expect(subject.rule_names.size).to eq(described_class.builtin_rules.size)

        described_class.builtin_rules.each do |rule_class|
          expect(subject.get(rule_class.rule_name)).to eq(rule_class)
        end
      end
    end

    context "with builtins: false" do
      subject { described_class.new(builtins: false) }

      it "starts with an empty registry" do
        expect(subject.rule_names.size).to eq(0)
      end
    end

    context "with rules argument" do
      it "registers all provided rules" do
        registry = described_class.new(builtins: false, rules: [test_rule_class, another_rule_class])
        expect(registry.rule_names.size).to eq(2)
        expect(registry.get("test-rule")).to eq(test_rule_class)
        expect(registry.get("another-rule")).to eq(another_rule_class)
      end
    end

    context "with both builtins and rules" do
      it "registers both built-in and provided rules" do
        registry = described_class.new(builtins: true, rules: [test_rule_class])
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

    context "with no exceptions" do
      it "builds instances of all registered rules" do
        rules = registry.build_all

        expect(rules.size).to eq(2)
        expect(rules[0]).to be_a(test_rule_class)
        expect(rules[1]).to be_a(another_rule_class)
      end
    end

    context "with exceptions" do
      it "builds instances of all rules except excluded ones" do
        rules = registry.build_all(except: ["test-rule"])

        expect(rules.size).to eq(1)
        expect(rules[0]).to be_a(another_rule_class)
      end
    end

    context "with multiple exceptions" do
      it "excludes all specified rules" do
        rules = registry.build_all(except: %w[test-rule another-rule])

        expect(rules).to be_empty
      end
    end

    context "when exception does not match any rule" do
      it "builds all rules" do
        rules = registry.build_all(except: ["nonexistent-rule"])

        expect(rules.size).to eq(2)
      end
    end

    context "when no rules are registered" do
      let(:empty_registry) { described_class.new(builtins: false) }

      it "returns an empty array" do
        rules = empty_registry.build_all

        expect(rules).to eq([])
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
