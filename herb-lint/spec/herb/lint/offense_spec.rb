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

  describe "#fixable?" do
    context "when autofix_context is present" do
      subject do
        described_class.new(
          rule_name: "html-img-require-alt",
          message: "Image missing alt attribute",
          severity: "error",
          location: build(:location),
          autofix_context: Herb::Lint::AutofixContext.new(
            node_location: build(:location),
            node_type: "HTMLElementNode",
            rule_class: Herb::Lint::Rules::HtmlImgRequireAlt
          )
        )
      end

      it "returns true" do
        expect(subject.fixable?).to be true
      end
    end

    context "when autofix_context is nil" do
      subject do
        described_class.new(
          rule_name: "html-img-require-alt",
          message: "Image missing alt attribute",
          severity: "error",
          location: build(:location)
        )
      end

      it "returns false" do
        expect(subject.fixable?).to be false
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
      expect(subject.fixable?).to be false
    end
  end
end
