# frozen_string_literal: true

RSpec.describe Herb::Lint::Offense do
  describe "#initialize" do
    subject { described_class.new(rule_name:, message:, severity:, location:) }

    let(:rule_name) { "alt-text" }
    let(:message) { "Image missing alt attribute" }
    let(:severity) { "error" }
    let(:location) { build_location(line: 10, column: 5) }

    it "sets all attributes correctly" do
      expect(subject.rule_name).to eq("alt-text")
      expect(subject.message).to eq("Image missing alt attribute")
      expect(subject.severity).to eq("error")
      expect(subject.location).to eq(location)
    end
  end

  describe "#line" do
    subject { offense.line }

    let(:offense) do
      described_class.new(
        rule_name: "alt-text",
        message: "Image missing alt attribute",
        severity: "error",
        location:
      )
    end
    let(:location) { build_location(line: 42, column: 10) }

    it "returns the start_line from location" do
      expect(subject).to eq(42)
    end
  end

  describe "#column" do
    subject { offense.column }

    let(:offense) do
      described_class.new(
        rule_name: "attribute-quotes",
        message: "Attribute should use double quotes",
        severity: "warning",
        location:
      )
    end
    let(:location) { build_location(line: 1, column: 25) }

    it "returns the start_column from location" do
      expect(subject).to eq(25)
    end
  end
end
