# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::TagNameLowercase do
  describe ".rule_name" do
    it "returns 'html-tag-name-lowercase'" do
      expect(described_class.rule_name).to eq("html-tag-name-lowercase")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Enforce lowercase tag names")
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

    context "when tag names are lowercase" do
      let(:source) { "<div>text</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when open tag has uppercase letters" do
      let(:source) { "<DIV>text</div>" }

      it "reports an offense for the open tag" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-tag-name-lowercase")
        expect(subject.first.message).to eq("Tag name 'DIV' should be lowercase")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when close tag has uppercase letters" do
      let(:source) { "<div>text</DIV>" }

      it "reports an offense for the close tag" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-tag-name-lowercase")
        expect(subject.first.message).to eq("Tag name 'DIV' should be lowercase")
      end
    end

    context "when both open and close tags have uppercase letters" do
      let(:source) { "<DIV>text</DIV>" }

      it "reports offenses for both tags" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to all(include("should be lowercase"))
      end
    end

    context "when tag has mixed case" do
      let(:source) { "<Div>text</Div>" }

      it "reports offenses for mixed case tags" do
        expect(subject.size).to eq(2)
        expect(subject.first.message).to eq("Tag name 'Div' should be lowercase")
      end
    end

    context "with multiple elements" do
      let(:source) do
        <<~HTML
          <DIV>
            <SPAN>text</SPAN>
          </DIV>
        HTML
      end

      it "reports offenses for all uppercase tags" do
        expect(subject.size).to eq(4)
      end
    end

    context "with nested elements having different cases" do
      let(:source) do
        <<~HTML
          <div>
            <SPAN>text</SPAN>
          </div>
        HTML
      end

      it "reports offenses only for uppercase tags" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to all(include("SPAN"))
      end
    end

    context "with void element in uppercase" do
      let(:source) { "<BR>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Tag name 'BR' should be lowercase")
      end
    end

    context "with void element in lowercase" do
      let(:source) { "<br>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end
  end

  describe "#autofix" do
    subject { described_class.new.autofix(node, document) }

    let(:document) { Herb.parse(source, track_whitespace: true) }

    context "when fixing uppercase open tag" do
      let(:source) { "<DIV>text</div>" }
      let(:expected) { "<div>text</div>" }
      let(:node) { document.value.children.first.open_tag }

      it "converts tag name to lowercase" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing uppercase close tag" do
      let(:source) { "<div>text</DIV>" }
      let(:expected) { "<div>text</div>" }
      let(:node) { document.value.children.first.close_tag }

      it "converts tag name to lowercase" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing both uppercase open and close tags" do
      let(:source) { "<DIV>text</DIV>" }
      let(:expected) { "<div>text</div>" }

      it "converts both tag names to lowercase" do
        element = document.value.children.first
        expect(described_class.new.autofix(element.open_tag, document)).to be(true)
        expect(described_class.new.autofix(element.close_tag, document)).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing mixed case tags" do
      let(:source) { "<Div>text</Div>" }
      let(:expected) { "<div>text</div>" }

      it "converts mixed case to lowercase" do
        element = document.value.children.first
        expect(described_class.new.autofix(element.open_tag, document)).to be(true)
        expect(described_class.new.autofix(element.close_tag, document)).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing void element with uppercase tag" do
      let(:source) { "<BR>" }
      let(:expected) { "<br>" }
      let(:node) { document.value.children.first.open_tag }

      it "converts void element tag name to lowercase" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing nested elements with uppercase tags" do
      let(:source) do
        <<~HTML
          <DIV>
            <SPAN>text</SPAN>
          </DIV>
        HTML
      end
      let(:expected) do
        <<~HTML
          <div>
            <span>text</span>
          </div>
        HTML
      end

      it "can fix each tag independently" do
        outer = document.value.children.first
        inner = outer.body.find { |c| c.is_a?(Herb::AST::HTMLElementNode) }

        expect(described_class.new.autofix(outer.open_tag, document)).to be(true)
        expect(described_class.new.autofix(outer.close_tag, document)).to be(true)
        expect(described_class.new.autofix(inner.open_tag, document)).to be(true)
        expect(described_class.new.autofix(inner.close_tag, document)).to be(true)

        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end
  end
end
