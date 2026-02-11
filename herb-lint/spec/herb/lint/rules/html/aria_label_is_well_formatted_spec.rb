# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::AriaLabelIsWellFormatted do
  describe ".rule_name" do
    it "returns 'html-aria-label-is-well-formatted'" do
      expect(described_class.rule_name).to eq("html-aria-label-is-well-formatted")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Require well-formatted aria-label values")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    subject { described_class.new(matcher:).check(document, context) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    # Good examples from documentation
    context "when aria-label is well-formatted (Close dialog)" do
      let(:source) { '<button aria-label="Close dialog">X</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when aria-label is well-formatted on input (Search products)" do
      let(:source) { '<input aria-label="Search products" type="search" autocomplete="off">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when aria-label starts with a number (Page 2 of 10)" do
      let(:source) { '<button aria-label="Page 2 of 10">2</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "when aria-label starts with lowercase" do
      let(:source) { '<button aria-label="close dialog">X</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "The `aria-label` attribute value text should be formatted like visual text. " \
          "Use sentence case (capitalize the first letter)."
        )
      end
    end

    context "when aria-label contains literal line breaks" do
      let(:source) { "<button aria-label=\"Close\ndialog\">X</button>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "The `aria-label` attribute value text should not contain line breaks. " \
          "Use concise, single-line descriptions."
        )
      end
    end

    context "when aria-label looks like an ID (snake_case)" do
      let(:source) { '<button aria-label="close_dialog">X</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "The `aria-label` attribute value should not be formatted like an ID. " \
          "Use natural, sentence-case text instead."
        )
      end
    end

    context "when aria-label looks like an ID (kebab-case)" do
      let(:source) { '<button aria-label="close-dialog">X</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "The `aria-label` attribute value should not be formatted like an ID. " \
          "Use natural, sentence-case text instead."
        )
      end
    end

    context "when aria-label looks like an ID (camelCase)" do
      let(:source) { '<button aria-label="closeDialog">X</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "The `aria-label` attribute value should not be formatted like an ID. " \
          "Use natural, sentence-case text instead."
        )
      end
    end

    context "when aria-label contains HTML entity line breaks" do
      let(:source) { '<button aria-label="Close&#10;dialog">X</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "The `aria-label` attribute value text should not contain line breaks. " \
          "Use concise, single-line descriptions."
        )
      end
    end

    # Additional edge case tests
    context "when aria-label starts with a number" do
      let(:source) { '<button aria-label="3 items in cart">Cart</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element has no aria-label" do
      let(:source) { "<button>Submit</button>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ARIA-LABEL attribute is uppercase" do
      let(:source) { '<button ARIA-LABEL="Submit form">Submit</button>' }

      it "does not report an offense (case insensitive)" do
        expect(subject).to be_empty
      end
    end

    context "with non-labeled elements" do
      let(:source) { '<div class="container"><p>Hello</p></div>' }

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end
  end
end
