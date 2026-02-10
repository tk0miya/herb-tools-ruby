# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::NoEmptyAttributes do
  describe ".rule_name" do
    it "returns 'html-no-empty-attributes'" do
      expect(described_class.rule_name).to eq("html-no-empty-attributes")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow empty attribute values")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    subject { described_class.new(matcher:).check(document, context) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    context "when attribute has a non-empty value" do
      let(:source) { '<div class="container">text</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when attribute has an empty value" do
      let(:source) { '<div class="">text</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-empty-attributes")
        expect(subject.first.message).to eq("Unexpected empty attribute value for 'class'")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when multiple attributes have empty values" do
      let(:source) { '<div class="" id="">text</div>' }

      it "reports an offense for each empty attribute" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to contain_exactly(
          "Unexpected empty attribute value for 'class'",
          "Unexpected empty attribute value for 'id'"
        )
      end
    end

    context "when alt attribute has an empty value" do
      let(:source) { '<img alt="">' }

      it "does not report an offense (alt='' is semantically valid)" do
        expect(subject).to be_empty
      end
    end

    context "when alt attribute has an empty value with uppercase name" do
      let(:source) { '<img ALT="">' }

      it "does not report an offense (case-insensitive check)" do
        expect(subject).to be_empty
      end
    end

    context "when boolean attribute has no value" do
      let(:source) { "<input disabled>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with mixed empty and non-empty attributes" do
      let(:source) { '<div class="" id="main">text</div>' }

      it "reports offense only for the empty attribute" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Unexpected empty attribute value for 'class'")
      end
    end

    context "with nested elements containing empty attributes" do
      let(:source) do
        <<~HTML
          <div class="">
            <span id="">text</span>
          </div>
        HTML
      end

      it "reports an offense for each element" do
        expect(subject.size).to eq(2)
      end
    end

    context "with element that has no attributes" do
      let(:source) { "<div>text</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with img element having both alt and other empty attributes" do
      let(:source) { '<img alt="" class="">' }

      it "reports offense only for the non-exempted attribute" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Unexpected empty attribute value for 'class'")
      end
    end
  end
end
