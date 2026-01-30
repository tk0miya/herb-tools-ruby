# frozen_string_literal: true

RSpec.describe Herb::Lint::DisableComment do
  describe "#disables_all?" do
    context "when rule_names includes 'all'" do
      subject { described_class.new(rule_names: ["all"], line: 1) }

      it "returns true" do
        expect(subject.disables_all?).to be true
      end
    end

    context "when rule_names contains specific rules" do
      subject { described_class.new(rule_names: ["alt-text", "html/lowercase-tags"], line: 1) }

      it "returns false" do
        expect(subject.disables_all?).to be false
      end
    end

    context "when rule_names is empty" do
      subject { described_class.new(rule_names: [], line: 1) }

      it "returns false" do
        expect(subject.disables_all?).to be false
      end
    end
  end

  describe "#disables_rule?" do
    context "when the rule is explicitly listed" do
      subject { described_class.new(rule_names: ["alt-text", "html/lowercase-tags"], line: 1) }

      it "returns true for a listed rule" do
        expect(subject.disables_rule?("alt-text")).to be true
        expect(subject.disables_rule?("html/lowercase-tags")).to be true
      end

      it "returns false for an unlisted rule" do
        expect(subject.disables_rule?("html/no-duplicate-id")).to be false
      end
    end

    context "when all rules are disabled" do
      subject { described_class.new(rule_names: ["all"], line: 1) }

      it "returns true for any rule" do
        expect(subject.disables_rule?("alt-text")).to be true
        expect(subject.disables_rule?("html/lowercase-tags")).to be true
        expect(subject.disables_rule?("some-other-rule")).to be true
      end
    end
  end

  describe "Data.define" do
    it "is a value object with rule_names and line" do
      comment = described_class.new(rule_names: ["alt-text"], line: 5)
      expect(comment.rule_names).to eq(["alt-text"])
      expect(comment.line).to eq(5)
    end

    it "supports equality by value" do
      a = described_class.new(rule_names: ["alt-text"], line: 5)
      b = described_class.new(rule_names: ["alt-text"], line: 5)
      expect(a).to eq(b)
    end
  end
end
