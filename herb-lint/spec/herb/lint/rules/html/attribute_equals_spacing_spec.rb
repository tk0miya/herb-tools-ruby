# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::AttributeEqualsSpacing do
  describe ".rule_name" do
    it "returns 'html-attribute-equals-spacing'" do
      expect(described_class.rule_name).to eq("html-attribute-equals-spacing")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow spaces around `=` in attribute assignments")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe ".safe_autofixable?" do
    it "returns true" do
      expect(described_class.safe_autofixable?).to be(true)
    end
  end

  describe "#check" do
    subject { described_class.new.check(document, context) }

    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    context "when attribute has no spaces around =" do
      let(:source) { '<div class="foo">text</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when attribute has space before =" do
      let(:source) { '<div class ="foo">text</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-attribute-equals-spacing")
        expect(subject.first.message).to eq("Unexpected space before `=` in attribute assignment")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when attribute has space after =" do
      let(:source) { '<div class= "foo">text</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Unexpected space after `=` in attribute assignment")
      end
    end

    context "when attribute has spaces on both sides of =" do
      let(:source) { '<div class = "foo">text</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Unexpected spaces around `=` in attribute assignment")
      end
    end

    context "when boolean attribute has no value" do
      let(:source) { "<input disabled>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiple attributes have spacing issues" do
      let(:source) { '<div class ="foo" id = "bar">text</div>' }

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("html-attribute-equals-spacing"))
      end
    end

    context "with mixed valid and invalid attributes" do
      let(:source) { '<div class="foo" id ="bar">text</div>' }

      it "reports offense only for the invalid attribute" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Unexpected space before `=` in attribute assignment")
      end
    end

    context "with nested elements having spacing issues" do
      let(:source) do
        <<~HTML
          <div class="outer">
            <span id = "inner">text</span>
          </div>
        HTML
      end

      it "reports offense with correct line number" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end

    context "with element that has no attributes" do
      let(:source) { "<div>text</div>" }

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end

    context "with multiple boolean attributes" do
      let(:source) { "<input disabled checked readonly>" }

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end
  end

  describe "#autofix" do
    subject { described_class.new.autofix(node, document) }

    let(:document) { Herb.parse(source, track_whitespace: true) }

    context "when fixing attribute with space before =" do
      let(:source) { '<div class ="foo">text</div>' }
      let(:expected) { '<div class="foo">text</div>' }
      let(:node) do
        div = document.value.children.find { |n| n.is_a?(Herb::AST::HTMLElementNode) }
        div.open_tag.children.find { |n| n.is_a?(Herb::AST::HTMLAttributeNode) }
      end

      it "removes the space before =" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing attribute with space after =" do
      let(:source) { '<div class= "foo">text</div>' }
      let(:expected) { '<div class="foo">text</div>' }
      let(:node) do
        div = document.value.children.find { |n| n.is_a?(Herb::AST::HTMLElementNode) }
        div.open_tag.children.find { |n| n.is_a?(Herb::AST::HTMLAttributeNode) }
      end

      it "removes the space after =" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing attribute with spaces on both sides of =" do
      let(:source) { '<div class = "foo">text</div>' }
      let(:expected) { '<div class="foo">text</div>' }
      let(:node) do
        div = document.value.children.find { |n| n.is_a?(Herb::AST::HTMLElementNode) }
        div.open_tag.children.find { |n| n.is_a?(Herb::AST::HTMLAttributeNode) }
      end

      it "removes spaces on both sides of =" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing attribute with tabs around =" do
      let(:source) { "<div class\t=\t\"foo\">text</div>" }
      let(:expected) { '<div class="foo">text</div>' }
      let(:node) do
        div = document.value.children.find { |n| n.is_a?(Herb::AST::HTMLElementNode) }
        div.open_tag.children.find { |n| n.is_a?(Herb::AST::HTMLAttributeNode) }
      end

      it "removes tabs around =" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing multiple attributes with spacing issues" do
      let(:source) { '<div class ="foo" id = "bar">text</div>' }
      let(:expected) { '<div class="foo" id="bar">text</div>' }

      it "can fix each attribute independently" do
        div = document.value.children.find { |n| n.is_a?(Herb::AST::HTMLElementNode) }
        attrs = div.open_tag.children.select { |n| n.is_a?(Herb::AST::HTMLAttributeNode) }
        expect(attrs.size).to eq(2)

        # Fix first attribute
        result1 = described_class.new.autofix(attrs[0], document)
        expect(result1).to be(true)

        # Fix second attribute
        result2 = described_class.new.autofix(attrs[1], document)
        expect(result2).to be(true)

        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end
  end
end
