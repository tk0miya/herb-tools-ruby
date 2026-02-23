# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::AttributeValuesRequireQuotes do
  describe ".rule_name" do
    it "returns 'html-attribute-values-require-quotes'" do
      expect(described_class.rule_name).to eq("html-attribute-values-require-quotes")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Require quotes around attribute values")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe ".safe_autofixable?" do
    it "returns true" do
      expect(described_class.safe_autofixable?).to be(true)
    end
  end

  describe "#check" do
    subject { described_class.new(matcher:).check(document, context) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    # Good examples from documentation
    context "with <div id=\"hello\"></div>" do
      let(:source) { '<div id="hello"></div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with <input type=\"text\" autocomplete=\"off\">" do
      let(:source) { '<input type="text" autocomplete="off">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with <a href=\"/profile\">Profile</a>" do
      let(:source) { '<a href="/profile">Profile</a>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "with <div id=hello></div>" do
      let(:source) { "<div id=hello></div>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-attribute-values-require-quotes")
        expect(subject.first.message).to eq("Attribute value should be quoted")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "with <input type=text autocomplete=\"off\">" do
      let(:source) { '<input type=text autocomplete="off">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "with <a href=profile></a>" do
      let(:source) { "<a href=profile></a>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    # Additional edge cases
    context "when attribute has single-quoted value" do
      let(:source) { "<div class='foo'>text</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when boolean attribute has no value" do
      let(:source) { "<input disabled />" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiple boolean attributes with no value" do
      let(:source) { "<input disabled checked readonly />" }

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end

    context "when multiple unquoted attributes" do
      let(:source) { "<div class=foo id=bar>text</div>" }

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("html-attribute-values-require-quotes"))
      end
    end

    context "with mixed quoted and unquoted attributes" do
      let(:source) { '<div class="foo" id=bar>text</div>' }

      it "reports offense only for unquoted attribute" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Attribute value should be quoted")
      end
    end

    context "with nested elements containing unquoted attributes" do
      let(:source) do
        <<~HTML
          <div class="outer">
            <span id=inner>text</span>
          </div>
        HTML
      end

      it "reports offense with correct line number" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end

    context "with empty quoted value" do
      let(:source) { '<input value="" />' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with element that has no attributes" do
      let(:source) { "<div>text</div>" }

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end
  end

  describe "#autofix" do
    subject { described_class.new(matcher:).autofix(node, document) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }

    context "when fixing a single unquoted attribute" do
      let(:source) { "<div class=foo>text</div>" }
      let(:expected) { '<div class="foo">text</div>' }
      let(:node) do
        document.value.children.first.open_tag.children.find { _1.is_a?(Herb::AST::HTMLAttributeNode) }
      end

      it "adds double quotes around the value" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing an unquoted attribute alongside a quoted one" do
      let(:source) { '<div class="foo" id=bar>text</div>' }
      let(:expected) { '<div class="foo" id="bar">text</div>' }
      let(:node) do
        document.value.children.first.open_tag.children.select { _1.is_a?(Herb::AST::HTMLAttributeNode) }.last
      end

      it "adds double quotes only to the unquoted attribute" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end
  end
end
