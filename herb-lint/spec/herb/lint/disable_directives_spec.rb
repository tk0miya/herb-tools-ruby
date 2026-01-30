# frozen_string_literal: true

RSpec.describe Herb::Lint::DisableDirectives do
  describe "#ignore_file?" do
    context "when constructed with ignore_file: true" do
      subject { described_class.new(comments: [], ignore_file: true) }

      it "returns true" do
        expect(subject.ignore_file?).to be true
      end
    end

    context "when constructed with ignore_file: false" do
      subject { described_class.new(comments: [], ignore_file: false) }

      it "returns false" do
        expect(subject.ignore_file?).to be false
      end
    end
  end

  describe "#rule_disabled?" do
    context "when a specific rule is disabled on the next line" do
      subject do
        comments = [Herb::Lint::DisableComment.new(rule_names: ["alt-text"], line: 1)]
        described_class.new(comments:, ignore_file: false)
      end

      it "returns true for the disabled rule on the target line" do
        expect(subject.rule_disabled?(2, "alt-text")).to be true
      end

      it "returns false for a different rule on the target line" do
        expect(subject.rule_disabled?(2, "html/lowercase-tags")).to be false
      end

      it "returns false for the disabled rule on a non-target line" do
        expect(subject.rule_disabled?(1, "alt-text")).to be false
        expect(subject.rule_disabled?(3, "alt-text")).to be false
      end
    end

    context "when all rules are disabled on the next line" do
      subject do
        comments = [Herb::Lint::DisableComment.new(rule_names: ["all"], line: 3)]
        described_class.new(comments:, ignore_file: false)
      end

      it "returns true for any rule on the target line" do
        expect(subject.rule_disabled?(4, "alt-text")).to be true
        expect(subject.rule_disabled?(4, "html/lowercase-tags")).to be true
      end

      it "returns false on non-target lines" do
        expect(subject.rule_disabled?(3, "alt-text")).to be false
        expect(subject.rule_disabled?(5, "alt-text")).to be false
      end
    end

    context "when there are multiple disable comments" do
      subject do
        comments = [
          Herb::Lint::DisableComment.new(rule_names: ["alt-text"], line: 1),
          Herb::Lint::DisableComment.new(rule_names: ["html/lowercase-tags"], line: 5)
        ]
        described_class.new(comments:, ignore_file: false)
      end

      it "disables the correct rule on each target line" do
        expect(subject.rule_disabled?(2, "alt-text")).to be true
        expect(subject.rule_disabled?(2, "html/lowercase-tags")).to be false
        expect(subject.rule_disabled?(6, "html/lowercase-tags")).to be true
        expect(subject.rule_disabled?(6, "alt-text")).to be false
      end
    end

    context "when there are no disable comments" do
      subject { described_class.new(comments: [], ignore_file: false) }

      it "returns false for any rule on any line" do
        expect(subject.rule_disabled?(1, "alt-text")).to be false
      end
    end
  end

  describe "#comments" do
    it "returns the comments passed to the constructor" do
      comments = [Herb::Lint::DisableComment.new(rule_names: ["alt-text"], line: 1)]
      directives = described_class.new(comments:, ignore_file: false)
      expect(directives.comments).to eq(comments)
    end
  end
end
