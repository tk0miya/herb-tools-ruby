# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HtmlBooleanAttributesNoValue do
  describe ".rule_name" do
    it "returns 'html-boolean-attributes-no-value'" do
      expect(described_class.rule_name).to eq("html-boolean-attributes-no-value")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Boolean attributes should not have values")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    subject { described_class.new.check(document, context) }

    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    context "when boolean attribute has no value" do
      let(:source) { "<input disabled>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiple boolean attributes have no values" do
      let(:source) { "<input disabled checked readonly>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when non-boolean attribute has a value" do
      let(:source) { '<input type="text" name="user">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when boolean attribute has a self-referencing value" do
      let(:source) { '<input disabled="disabled">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-boolean-attributes-no-value")
        expect(subject.first.message).to eq("Boolean attribute 'disabled' should not have a value")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when boolean attribute has value 'true'" do
      let(:source) { '<button disabled="true">Submit</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Boolean attribute 'disabled' should not have a value")
      end
    end

    context "when multiple boolean attributes have values" do
      let(:source) { '<input checked="checked" disabled="disabled">' }

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to contain_exactly(
          "Boolean attribute 'checked' should not have a value",
          "Boolean attribute 'disabled' should not have a value"
        )
      end
    end

    context "when boolean attribute has uppercase name with value" do
      let(:source) { '<input DISABLED="disabled">' }

      it "reports an offense (case-insensitive check)" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Boolean attribute 'DISABLED' should not have a value")
      end
    end

    context "when boolean attribute has an arbitrary value" do
      let(:source) { '<video controls="something-else"></video>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Boolean attribute 'controls' should not have a value")
      end
    end

    context "with mixed boolean and non-boolean attributes" do
      let(:source) { '<form novalidate="novalidate" action="/submit" method="post"></form>' }

      it "reports offense only for the boolean attribute" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Boolean attribute 'novalidate' should not have a value")
      end
    end

    context "with element having no attributes" do
      let(:source) { "<div>text</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with nested elements having boolean attributes with values" do
      let(:source) do
        <<~HTML
          <form>
            <input disabled="disabled">
            <button type="submit">Submit</button>
          </form>
        HTML
      end

      it "reports offense only for boolean attribute with value" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Boolean attribute 'disabled' should not have a value")
        expect(subject.first.line).to eq(2)
      end
    end
  end
end
