# frozen_string_literal: true

require "herb/config"

RSpec.describe Herb::Lint::Context do
  subject { described_class.new(file_path:, source:, config:, rule_registry:) }

  let(:file_path) { "app/views/users/index.html.erb" }
  let(:source) { '<img src="test.png">' }
  let(:config) { Herb::Config::LinterConfig.new(config_hash) }
  let(:config_hash) { {} }
  let(:rule_registry) { nil }

  describe "#file_path" do
    it "returns the file path" do
      expect(subject.file_path).to eq("app/views/users/index.html.erb")
    end
  end

  describe "#source" do
    it "returns the source code" do
      expect(subject.source).to eq('<img src="test.png">')
    end
  end

  describe "#config" do
    it "returns the configuration" do
      expect(subject.config).to eq(config)
    end
  end

  describe "#severity_for" do
    context "when rule severity is configured" do
      let(:config_hash) do
        {
          "linter" => {
            "rules" => {
              "alt-text" => "error",
              "attribute-quotes" => { "severity" => "warn" }
            }
          }
        }
      end

      it "returns the configured severity for string config" do
        expect(subject.severity_for("alt-text")).to eq("error")
      end

      it "returns the configured severity for hash config" do
        expect(subject.severity_for("attribute-quotes")).to eq("warn")
      end
    end

    context "when rule severity is not configured but rule_registry is provided" do
      let(:rule_registry) { Herb::Lint::RuleRegistry.new }
      let(:test_rule_class) do
        Class.new(Herb::Lint::Rules::Base) do
          def self.rule_name = "test-rule"
          def self.default_severity = "info"
        end
      end

      before { rule_registry.register(test_rule_class) }

      it "returns the rule's default severity" do
        expect(subject.severity_for("test-rule")).to eq("info")
      end
    end

    context "when rule severity is not configured and rule is not in registry" do
      let(:rule_registry) { Herb::Lint::RuleRegistry.new }

      it "returns 'error' as the default" do
        expect(subject.severity_for("unknown-rule")).to eq("error")
      end
    end

    context "when rule severity is not configured and no rule_registry" do
      it "returns 'error' as the default" do
        expect(subject.severity_for("unknown-rule")).to eq("error")
      end
    end

    context "when configured severity overrides rule default" do
      let(:rule_registry) { Herb::Lint::RuleRegistry.new }
      let(:config_hash) do
        {
          "linter" => {
            "rules" => {
              "test-rule" => "warn"
            }
          }
        }
      end
      let(:test_rule_class) do
        Class.new(Herb::Lint::Rules::Base) do
          def self.rule_name = "test-rule"
          def self.default_severity = "error"
        end
      end

      before { rule_registry.register(test_rule_class) }

      it "prefers the configured severity over the rule default" do
        expect(subject.severity_for("test-rule")).to eq("warn")
      end
    end
  end
end
