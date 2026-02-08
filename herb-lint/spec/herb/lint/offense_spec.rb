# frozen_string_literal: true

RSpec.describe Herb::Lint::Offense do
  describe "#initialize" do
    subject { described_class.new(rule_name:, message:, severity:, location:) }

    let(:rule_name) { "html-img-require-alt" }
    let(:message) { "Image missing alt attribute" }
    let(:severity) { "error" }
    let(:location) { build(:location) }

    it "sets all attributes correctly" do
      expect(subject.rule_name).to eq("html-img-require-alt")
      expect(subject.message).to eq("Image missing alt attribute")
      expect(subject.severity).to eq("error")
      expect(subject.location).to eq(location)
    end
  end

  describe "#line" do
    subject { offense.line }

    let(:offense) do
      described_class.new(
        rule_name: "html-img-require-alt",
        message: "Image missing alt attribute",
        severity: "error",
        location: build(:location, start_line: 42)
      )
    end

    it "returns the start_line from location" do
      expect(subject).to eq(42)
    end
  end

  describe "#column" do
    subject { offense.column }

    let(:offense) do
      described_class.new(
        rule_name: "html-attribute-double-quotes",
        message: "Attribute should use double quotes",
        severity: "warning",
        location: build(:location, start_column: 25)
      )
    end

    it "returns the start_column from location" do
      expect(subject).to eq(25)
    end
  end

  describe "#autofixable?" do
    subject { offense.autofixable?(unsafe:) }

    let(:node) { Herb.parse('<img src="test.png">', track_whitespace: true).value.children.first }
    let(:safe_rule_class) do
      Class.new(Herb::Lint::Rules::VisitorRule) do
        def self.rule_name = "test/safe-rule"
        def self.description = "Safe test rule"
        def self.safe_autofixable? = true
      end
    end
    let(:unsafe_rule_class) do
      Class.new(Herb::Lint::Rules::VisitorRule) do
        def self.rule_name = "test/unsafe-rule"
        def self.description = "Unsafe test rule"
        def self.unsafe_autofixable? = true
      end
    end
    let(:offense) do
      described_class.new(
        rule_name: "test-rule",
        message: "Test",
        severity: "error",
        location: build(:location),
        autofix_context:
      )
    end
    let(:autofix_context) { nil }

    context "with unsafe: false" do
      let(:unsafe) { false }

      context "when rule declares safe_autofixable?" do
        let(:autofix_context) { Herb::Lint::AutofixContext.new(node:, rule_class: safe_rule_class) }

        it { is_expected.to be true }
      end

      context "when rule declares unsafe_autofixable?" do
        let(:autofix_context) { Herb::Lint::AutofixContext.new(node:, rule_class: unsafe_rule_class) }

        it { is_expected.to be false }
      end

      context "when autofix_context is nil" do
        it { is_expected.to be_nil }
      end
    end

    context "with unsafe: true" do
      let(:unsafe) { true }

      context "when rule declares safe_autofixable?" do
        let(:autofix_context) { Herb::Lint::AutofixContext.new(node:, rule_class: safe_rule_class) }

        it { is_expected.to be true }
      end

      context "when rule declares unsafe_autofixable?" do
        let(:autofix_context) { Herb::Lint::AutofixContext.new(node:, rule_class: unsafe_rule_class) }

        it { is_expected.to be true }
      end

      context "when autofix_context is nil" do
        it { is_expected.to be_nil }
      end
    end
  end

  describe "backward compatibility" do
    subject { described_class.new(rule_name:, message:, severity:, location:) }

    let(:rule_name) { "test-rule" }
    let(:message) { "Test message" }
    let(:severity) { "warning" }
    let(:location) { build(:location) }

    it "creates offense without autofix_context" do
      expect(subject.rule_name).to eq("test-rule")
      expect(subject.autofix_context).to be_nil
      expect(subject).not_to be_autofixable
    end
  end
end
