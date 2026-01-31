# frozen_string_literal: true

RSpec.describe Herb::Lint::Offense do
  describe "#initialize" do
    subject { described_class.new(rule_name:, message:, severity:, location:) }

    let(:rule_name) { "html-img-require-alt" }
    let(:message) { "Image missing alt attribute" }
    let(:severity) { "error" }
    let(:location) { build_location(line: 10, column: 5) }

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
        rule_name: "html-attribute-double-quotes",
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

  describe "#fixable?" do
    let(:location) { build_location(line: 1, column: 0) }

    context "when fix is nil" do
      subject do
        described_class.new(rule_name: "test-rule", message: "msg", severity: "warning", location:)
      end

      it "returns false" do
        expect(subject.fixable?).to be(false)
      end
    end

    context "when fix is provided" do
      subject do
        described_class.new(rule_name: "test-rule", message: "msg", severity: "warning", location:,
                            fix: ->(src) { src })
      end

      it "returns true" do
        expect(subject.fixable?).to be(true)
      end
    end
  end

  describe "#unsafe" do
    let(:location) { build_location(line: 1, column: 0) }

    context "when unsafe is not specified" do
      subject do
        described_class.new(rule_name: "test-rule", message: "msg", severity: "warning", location:)
      end

      it "defaults to false" do
        expect(subject.unsafe).to be(false)
      end
    end

    context "when unsafe is true" do
      subject do
        described_class.new(rule_name: "test-rule", message: "msg", severity: "warning", location:,
                            unsafe: true)
      end

      it "returns true" do
        expect(subject.unsafe).to be(true)
      end
    end
  end
end
