# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::AriaLevelMustBeValid do
  describe ".rule_name" do
    it "returns 'html-aria-level-must-be-valid'" do
      expect(described_class.rule_name).to eq("html-aria-level-must-be-valid")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("aria-level attribute must have a valid integer value (1-6)")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    subject { described_class.new(matcher:).check(document, context) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    context "when aria-level is 1" do
      let(:source) { '<div role="heading" aria-level="1">Heading</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when aria-level is 6" do
      let(:source) { '<div role="heading" aria-level="6">Heading</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when aria-level is 0" do
      let(:source) { '<div role="heading" aria-level="0">Heading</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-aria-level-must-be-valid")
        expect(subject.first.message).to eq("aria-level must be a valid integer between 1 and 6, got '0'")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when aria-level is 7" do
      let(:source) { '<div role="heading" aria-level="7">Heading</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("aria-level must be a valid integer between 1 and 6, got '7'")
      end
    end

    context "when aria-level is a non-numeric string" do
      let(:source) { '<div role="heading" aria-level="abc">Heading</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("aria-level must be a valid integer between 1 and 6, got 'abc'")
      end
    end

    context "when there is no aria-level attribute" do
      let(:source) { '<div role="heading">Heading</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when there are multiple elements with invalid aria-level" do
      let(:source) do
        <<~HTML
          <div role="heading" aria-level="0">First</div>
          <div role="heading" aria-level="7">Second</div>
        HTML
      end

      it "reports an offense for each element" do
        expect(subject.size).to eq(2)
      end
    end

    context "when only some elements have invalid aria-level" do
      let(:source) do
        <<~HTML
          <div role="heading" aria-level="2">Valid</div>
          <div role="heading" aria-level="0">Invalid</div>
          <div role="heading" aria-level="4">Valid</div>
        HTML
      end

      it "reports an offense only for the invalid value" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("aria-level must be a valid integer between 1 and 6, got '0'")
      end
    end

    context "with aria-level attribute in different case" do
      let(:source) { '<div role="heading" ARIA-LEVEL="0">Heading</div>' }

      it "reports an offense (case-insensitive check)" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-aria-level-must-be-valid")
      end
    end

    context "with nested elements" do
      let(:source) do
        <<~HTML
          <div role="heading" aria-level="0">
            <span role="heading" aria-level="8">Nested</span>
          </div>
        HTML
      end

      it "reports an offense for each element" do
        expect(subject.size).to eq(2)
      end
    end

    context "with other attributes present" do
      let(:source) { '<div class="title" role="heading" aria-level="0" id="main-heading">Heading</div>' }

      it "reports an offense for the invalid aria-level" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("aria-level must be a valid integer between 1 and 6, got '0'")
      end
    end
  end
end
