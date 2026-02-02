# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HtmlNoUnderscoresInAttributeNames do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template, track_whitespace: true) }
  let(:context) { build(:context) }

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
    context "when attribute names use hyphens" do
      let(:template) { '<div data-value="foo">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when standard attributes have no underscores" do
      let(:template) { '<input type="text" name="user" class="form-control">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when attribute name contains an underscore" do
      let(:template) { '<div data_value="foo">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-underscores-in-attribute-names")
        expect(subject.first.message).to eq(
          "Attribute name 'data_value' should not contain underscores; use hyphens instead"
        )
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when attribute name contains multiple underscores" do
      let(:template) { '<div my_custom_attr="bar">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "Attribute name 'my_custom_attr' should not contain underscores; use hyphens instead"
        )
      end
    end

    context "when multiple attributes contain underscores" do
      let(:template) { '<div data_value="foo" data_type="bar">' }

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to contain_exactly(
          "Attribute name 'data_value' should not contain underscores; use hyphens instead",
          "Attribute name 'data_type' should not contain underscores; use hyphens instead"
        )
      end
    end

    context "when some attributes have underscores and some do not" do
      let(:template) { '<div class="foo" data_value="bar" id="baz">' }

      it "reports offense only for the attribute with underscore" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "Attribute name 'data_value' should not contain underscores; use hyphens instead"
        )
      end
    end

    context "when element has no attributes" do
      let(:template) { "<div>text</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when boolean attribute has no underscore" do
      let(:template) { "<input disabled>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with nested elements having underscored attributes" do
      let(:template) do
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
          "Attribute name 'data_info' should not contain underscores; use hyphens instead"
        )
        expect(subject.first.line).to eq(2)
      end
    end

    context "when attribute value contains underscores but name does not" do
      let(:template) { '<div data-value="some_value">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with self-closing element having underscored attribute" do
      let(:template) { '<img src_set="image.png">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "Attribute name 'src_set' should not contain underscores; use hyphens instead"
        )
      end
    end
  end
end
