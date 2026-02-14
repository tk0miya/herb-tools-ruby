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
    context "when attribute has no spaces around =" do
      let(:source) { '<div class="container"></div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiple attributes with no spaces" do
      let(:source) { '<img src="/logo.png" alt="Logo">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when attribute with ERB value has no spaces" do
      let(:source) { '<input type="text" value="<%= @value %>" autocomplete="off">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "when attribute has space before =" do
      let(:source) { '<div class ="container"></div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-attribute-equals-spacing")
        expect(subject.first.message).to eq("Remove whitespace before `=` in HTML attribute")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when attribute has space after =" do
      let(:source) { '<img src= "/logo.png" alt="Logo">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Remove whitespace after `=` in HTML attribute")
      end
    end

    context "when attribute has spaces on both sides of =" do
      let(:source) { '<input type = "text" autocomplete="off">' }

      it "reports two offenses" do
        expect(subject.size).to eq(2)
        expect(subject[0].message).to eq("Remove whitespace before `=` in HTML attribute")
        expect(subject[1].message).to eq("Remove whitespace after `=` in HTML attribute")
      end
    end

    # Edge cases
    context "when boolean attribute has no value" do
      let(:source) { "<input disabled>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiple attributes have spacing issues" do
      let(:source) { '<div class ="foo" id = "bar">text</div>' }

      it "reports an offense for each" do
        expect(subject.size).to eq(3)
        expect(subject.map(&:rule_name)).to all(eq("html-attribute-equals-spacing"))
      end
    end

    context "with mixed valid and invalid attributes" do
      let(:source) { '<div class="foo" id ="bar">text</div>' }

      it "reports offense only for the invalid attribute" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Remove whitespace before `=` in HTML attribute")
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

      it "reports offenses with correct line number" do
        expect(subject.size).to eq(2)
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
    subject { described_class.new(matcher:).autofix(node, document) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }

    context "when fixing attribute with space before =" do
      let(:source) { '<div class ="container"></div>' }
      let(:expected) { '<div class="container"></div>' }
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
      let(:source) { '<img src= "/logo.png" alt="Logo">' }
      let(:expected) { '<img src="/logo.png" alt="Logo">' }
      let(:node) do
        img = document.value.children.find { |n| n.is_a?(Herb::AST::HTMLElementNode) }
        img.open_tag.children.find { |n| n.is_a?(Herb::AST::HTMLAttributeNode) }
      end

      it "removes the space after =" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing attribute with spaces on both sides of =" do
      let(:source) { '<input type = "text" autocomplete="off">' }
      let(:expected) { '<input type="text" autocomplete="off">' }
      let(:node) do
        input = document.value.children.find { |n| n.is_a?(Herb::AST::HTMLElementNode) }
        input.open_tag.children.find { |n| n.is_a?(Herb::AST::HTMLAttributeNode) }
      end

      it "removes spaces on both sides of =" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end
  end
end
