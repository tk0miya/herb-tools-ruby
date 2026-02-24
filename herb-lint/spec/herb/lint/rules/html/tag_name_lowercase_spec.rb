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
    it "returns 'error'" do
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
    context "with lowercase div element (documentation example)" do
      let(:source) { '<div class="container"></div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with lowercase input void element (documentation example)" do
      let(:source) { '<input type="text" name="username" autocomplete="off">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with lowercase span element (documentation example)" do
      let(:source) { "<span>Label</span>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with ERB content_tag helper (documentation example)" do
      let(:source) { '<%= content_tag(:div, "Hello world!") %>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "with uppercase DIV element (documentation example)" do
      let(:source) { '<DIV class="container"></DIV>' }

      it "reports an offense" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("html-tag-name-lowercase"))
        expect(subject.map(&:severity)).to all(eq("error"))
      end
    end

    context "with mixed case Input void element (documentation example)" do
      let(:source) { '<Input type="text" name="username" autocomplete="off">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-tag-name-lowercase")
        expect(subject.first.message).to include("Input")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "with mixed case Span element (documentation example)" do
      let(:source) { "<Span>Label</Span>" }

      it "reports an offense" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("html-tag-name-lowercase"))
      end
    end

    context "with ERB content_tag helper using mixed case (documentation example, TODO)" do
      let(:source) { '<%= content_tag(:DiV, "Hello world!") %>' }

      # TODO: This is listed as a Bad example in the documentation but is not
      # yet detected by this rule as it requires ERB expression analysis
      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Additional edge case tests
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

    context "with SVG child elements using case-sensitive names" do
      let(:source) { "<svg><linearGradient id=\"grad\"></linearGradient><clipPath id=\"clip\"></clipPath></svg>" }

      it "does not report an offense for SVG child elements" do
        expect(subject).to be_empty
      end
    end
  end

  describe "#autofix" do
    subject { described_class.new(matcher:).autofix(node, document) }

    let(:matcher) { build(:pattern_matcher) }
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
  end
end
