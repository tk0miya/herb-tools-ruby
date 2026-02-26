# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::NoUnderscoresInAttributeNames do
  describe ".rule_name" do
    it "returns 'html-no-underscores-in-attribute-names'" do
      expect(described_class.rule_name).to eq("html-no-underscores-in-attribute-names")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow underscores in HTML attribute names")
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

    # Good examples from documentation
    context "when attribute name uses hyphens (data-user-id)" do
      let(:source) { '<div data-user-id="123"></div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when attribute name uses hyphens (aria-label)" do
      let(:source) { '<img aria-label="Close" alt="Close">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when dynamic attribute name uses hyphens" do
      let(:source) { '<div data-<%= key %>-attribute="value"></div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "when attribute name contains underscores (data_user_id)" do
      let(:source) { '<div data_user_id="123"></div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-underscores-in-attribute-names")
        expect(subject.first.message).to eq(
          "Attribute `data_user_id` should not contain underscores. Use hyphens (-) instead."
        )
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when attribute name contains underscores (aria_label)" do
      let(:source) { '<img aria_label="Close" alt="Close">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-underscores-in-attribute-names")
        expect(subject.first.message).to eq(
          "Attribute `aria_label` should not contain underscores. Use hyphens (-) instead."
        )
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when dynamic attribute name has underscore in static suffix" do
      let(:source) { '<div data-<%= key %>_attribute="value"></div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-underscores-in-attribute-names")
        expect(subject.first.message).to eq(
          "Attribute `data-<%= key %>_attribute` should not contain underscores. Use hyphens (-) instead."
        )
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when multiple attributes contain underscores" do
      let(:source) { '<div data_value="foo" data_type="bar">' }

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to contain_exactly(
          "Attribute `data_value` should not contain underscores. Use hyphens (-) instead.",
          "Attribute `data_type` should not contain underscores. Use hyphens (-) instead."
        )
      end
    end

    context "when some attributes have underscores and some do not" do
      let(:source) { '<div class="foo" data_value="bar" id="baz">' }

      it "reports offense only for the attribute with underscore" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "Attribute `data_value` should not contain underscores. Use hyphens (-) instead."
        )
      end
    end

    context "when element has no attributes" do
      let(:source) { "<div>text</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when boolean attribute has no underscore" do
      let(:source) { "<input disabled>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with nested elements having underscored attributes" do
      let(:source) do
        <<~HTML
          <div>
            <span data_info="test">text</span>
            <input type="text">
          </div>
        HTML
      end

      it "reports offense only for the attribute with underscore" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "Attribute `data_info` should not contain underscores. Use hyphens (-) instead."
        )
        expect(subject.first.line).to eq(2)
      end
    end

    context "when attribute value contains underscores but name does not" do
      let(:source) { '<div data-value="some_value">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with self-closing element having underscored attribute" do
      let(:source) { '<img src_set="image.png">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "Attribute `src_set` should not contain underscores. Use hyphens (-) instead."
        )
      end
    end
  end
end
