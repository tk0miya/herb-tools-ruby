# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::BooleanAttributesNoValue do
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
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    subject { described_class.new(matcher:).check(document, context) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    # Good examples from documentation
    context "with checked attribute without value" do
      let(:source) { '<input type="checkbox" checked>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with disabled attribute without value" do
      let(:source) { "<button disabled>Submit</button>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with multiple attribute without value" do
      let(:source) { "<select multiple></select>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "with checked attribute with self-referencing value" do
      let(:source) { '<input type="checkbox" checked="checked">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-boolean-attributes-no-value")
        expect(subject.first.message).to eq(
          'Boolean attribute `checked` should not have a value. Use `checked` instead of `checked="checked"`.'
        )
        expect(subject.first.severity).to eq("error")
      end
    end

    context "with disabled attribute with value 'true'" do
      let(:source) { '<button disabled="true">Submit</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          'Boolean attribute `disabled` should not have a value. Use `disabled` instead of `disabled="true"`.'
        )
      end
    end

    context "with multiple attribute with self-referencing value" do
      let(:source) { '<select multiple="multiple"></select>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          'Boolean attribute `multiple` should not have a value. Use `multiple` instead of `multiple="multiple"`.'
        )
      end
    end

    # Additional edge cases
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

    context "when multiple boolean attributes have values" do
      let(:source) { '<input checked="checked" disabled="disabled">' }

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to contain_exactly(
          'Boolean attribute `checked` should not have a value. Use `checked` instead of `checked="checked"`.',
          'Boolean attribute `disabled` should not have a value. Use `disabled` instead of `disabled="disabled"`.'
        )
      end
    end

    context "when boolean attribute has uppercase name with value" do
      let(:source) { '<input DISABLED="disabled">' }

      it "reports an offense (case-insensitive check)" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          'Boolean attribute `DISABLED` should not have a value. Use `disabled` instead of `DISABLED="disabled"`.'
        )
      end
    end

    context "when boolean attribute has an arbitrary value" do
      let(:source) { '<video controls="something-else"></video>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          'Boolean attribute `controls` should not have a value. Use `controls` instead of `controls="something-else"`.'
        )
      end
    end

    context "with mixed boolean and non-boolean attributes" do
      let(:source) { '<form novalidate="novalidate" action="/submit" method="post"></form>' }

      it "reports offense only for the boolean attribute" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "Boolean attribute `novalidate` should not have a value. " \
          "Use `novalidate` instead of `novalidate=\"novalidate\"`."
        )
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
        expect(subject.first.message).to eq(
          'Boolean attribute `disabled` should not have a value. Use `disabled` instead of `disabled="disabled"`.'
        )
        expect(subject.first.line).to eq(2)
      end
    end
  end

  describe "#autofix" do
    subject { described_class.new(matcher:).autofix(node, document) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }

    context "when fixing a boolean attribute with self-referencing value" do
      let(:source) { '<input disabled="disabled">' }
      let(:expected) { "<input disabled>" }
      let(:node) do
        document.value.children.first.open_tag.children.find { |c| c.is_a?(Herb::AST::HTMLAttributeNode) }
      end

      it "removes the value" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing mixed boolean and non-boolean attributes" do
      let(:source) { '<form novalidate="novalidate" action="/submit" method="post"></form>' }
      let(:expected) { '<form novalidate action="/submit" method="post"></form>' }
      let(:node) do
        document.value.children.first.open_tag.children.find do |c|
          next false unless c.is_a?(Herb::AST::HTMLAttributeNode)

          attr_name = c.name.children.first&.content
          attr_name&.downcase == "novalidate"
        end
      end

      it "removes value only from the boolean attribute" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end
  end
end
