# frozen_string_literal: true

require "herb/config"

RSpec.describe Herb::Lint::Context do
  let(:context) { described_class.new(file_path:, source:, config:, directives:, rule_registry:) }
  let(:file_path) { "app/views/users/index.html.erb" }
  let(:source) { '<img src="test.png">' }
  let(:config) { Herb::Config::LinterConfig.new(config_hash) }
  let(:config_hash) { {} }
  let(:directives) { Herb::Lint::DirectiveParser.parse(Herb.parse(source, track_whitespace: true), source) }
  let(:rule_registry) { nil }

  describe "#file_path" do
    subject { context.file_path }

    it { is_expected.to eq("app/views/users/index.html.erb") }
  end

  describe "#source" do
    subject { context.source }

    it { is_expected.to eq('<img src="test.png">') }
  end

  describe "#config" do
    subject { context.config }

    it { is_expected.to eq(config) }
  end

  describe "#severity_for" do
    subject { context.severity_for(rule_name) }

    let(:rule_name) { "test-rule" }

    context "when rule severity is configured" do
      let(:config_hash) { { "linter" => { "rules" => { "test-rule" => { "severity" => "warning" } } } } }

      it { is_expected.to eq("warning") }
    end

    context "when rule severity is not configured but rule_registry is provided" do
      let(:rule_registry) { Herb::Lint::RuleRegistry.new(builtins: false, config:) }
      let(:test_rule_class) do
        Class.new(Herb::Lint::Rules::VisitorRule) do
          def self.rule_name = "test-rule"
          def self.description = "Test rule"
          def self.default_severity = "info"
          def self.safe_autofixable? = false
          def self.unsafe_autofixable? = false
        end
      end

      before { rule_registry.register(test_rule_class) }

      it { is_expected.to eq("info") }
    end

    context "when rule severity is not configured and rule is not in registry" do
      let(:rule_registry) { Herb::Lint::RuleRegistry.new(builtins: false, config:) }

      it { is_expected.to eq("error") }
    end

    context "when rule severity is not configured and no rule_registry" do
      it { is_expected.to eq("error") }
    end

    context "when configured severity overrides rule default" do
      let(:rule_registry) { Herb::Lint::RuleRegistry.new(builtins: false, config:) }
      let(:config_hash) { { "linter" => { "rules" => { "test-rule" => { "severity" => "warning" } } } } }
      let(:test_rule_class) do
        Class.new(Herb::Lint::Rules::VisitorRule) do
          def self.rule_name = "test-rule"
          def self.description = "Test rule"
          def self.default_severity = "error"
          def self.safe_autofixable? = false
          def self.unsafe_autofixable? = false
        end
      end

      before { rule_registry.register(test_rule_class) }

      it { is_expected.to eq("warning") }
    end
  end
end
