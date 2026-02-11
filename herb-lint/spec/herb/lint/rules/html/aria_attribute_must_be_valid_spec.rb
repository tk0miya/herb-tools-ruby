# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::AriaAttributeMustBeValid do
  describe ".rule_name" do
    it "returns 'html-aria-attribute-must-be-valid'" do
      expect(described_class.rule_name).to eq("html-aria-attribute-must-be-valid")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("ARIA attributes must be valid")
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

    # Good examples from documentation
    context "when div has valid aria-pressed attribute" do
      let(:source) { '<div role="button" aria-pressed="false">Toggle</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when input has valid aria-label attribute" do
      let(:source) { '<input type="text" aria-label="Search" autocomplete="off">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when span has valid aria-level attribute" do
      let(:source) { '<span role="heading" aria-level="2">Title</span>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "when div has typo in aria-pressed attribute" do
      let(:source) { '<div role="button" aria-presed="false">Toggle</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-aria-attribute-must-be-valid")
        expect(subject.first.message).to include("aria-presed")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when input has typo in aria-label attribute" do
      let(:source) { '<input type="text" aria-lable="Search" autocomplete="off">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-aria-attribute-must-be-valid")
        expect(subject.first.message).to include("aria-lable")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when span has non-existent aria-size attribute" do
      let(:source) { '<span aria-size="large" role="heading" aria-level="2">Title</span>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-aria-attribute-must-be-valid")
        expect(subject.first.message).to include("aria-size")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when element has valid ARIA attributes" do
      let(:source) do
        '<div aria-label="Name" aria-describedby="desc" aria-expanded="false">content</div>'
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element has multiple invalid ARIA attributes" do
      let(:source) { '<div aria-labelled="Name" aria-foo="bar">content</div>' }

      it "reports an offense for each invalid attribute" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to contain_exactly(
          "The attribute `aria-labelled` is not a valid ARIA attribute. " \
          "ARIA attributes must match the WAI-ARIA specification.",
          "The attribute `aria-foo` is not a valid ARIA attribute. " \
          "ARIA attributes must match the WAI-ARIA specification."
        )
      end
    end

    context "when element has mixed valid and invalid ARIA attributes" do
      let(:source) { '<div aria-label="Name" aria-labelled="Name">content</div>' }

      it "reports offense only for the invalid attribute" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "The attribute `aria-labelled` is not a valid ARIA attribute. " \
          "ARIA attributes must match the WAI-ARIA specification."
        )
      end
    end

    context "when element has non-aria attributes" do
      let(:source) { '<div class="container" id="main">content</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ARIA attribute has uppercase letters" do
      let(:source) { '<div ARIA-LABELLED="Name">content</div>' }

      it "reports an offense (case-insensitive check)" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "The attribute `ARIA-LABELLED` is not a valid ARIA attribute. " \
          "ARIA attributes must match the WAI-ARIA specification."
        )
      end
    end

    context "when valid ARIA attribute has uppercase letters" do
      let(:source) { '<div ARIA-LABEL="Name">content</div>' }

      it "does not report an offense (case-insensitive check)" do
        expect(subject).to be_empty
      end
    end

    context "when element has no attributes" do
      let(:source) { "<div>content</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with nested elements having invalid ARIA attributes" do
      let(:source) do
        <<~HTML
          <div aria-labelled="outer">
            <span aria-foo="inner">text</span>
          </div>
        HTML
      end

      it "reports an offense for each element" do
        expect(subject.size).to eq(2)
      end
    end
  end
end
