# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::AttributeDoubleQuotes do
  describe ".rule_name" do
    it "returns 'html-attribute-double-quotes'" do
      expect(described_class.rule_name).to eq("html-attribute-double-quotes")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Prefer double quotes for HTML attribute values")
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
    subject { described_class.new(matcher:).check(document, context) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    # Good examples from documentation
    context "when attribute uses double quotes" do
      let(:source) { '<input type="text" autocomplete="off">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when attribute uses double quotes (link)" do
      let(:source) { '<a href="/profile">Profile</a>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when attribute uses double quotes (data attribute)" do
      let(:source) { '<div data-action="click->dropdown#toggle"></div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when single quotes used but value contains double quotes (exception)" do
      let(:source) { '<div id=\'"hello"\' title=\'Say "Hello" to the world\'></div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "when attribute uses single quotes" do
      let(:source) { '<input type=\'text\' autocomplete="off">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-attribute-double-quotes")
        expect(subject.first.message).to include("Attribute `type` uses single quotes")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when attribute uses single quotes (link)" do
      let(:source) { "<a href='/profile'>Profile</a>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Attribute `href` uses single quotes")
      end
    end

    context "when attribute uses single quotes (data attribute)" do
      let(:source) { "<div data-action='click->dropdown#toggle'></div>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Attribute `data-action` uses single quotes")
      end
    end

    # Additional edge case tests
    context "when boolean attribute has no value" do
      let(:source) { "<input disabled />" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when attribute has unquoted value" do
      let(:source) { "<div class=container>text</div>" }

      it "does not report an offense (unquoted values are not checked by this rule)" do
        expect(subject).to be_empty
      end
    end

    context "with multiple single-quoted attributes" do
      let(:source) { "<div class='container' id='main'>text</div>" }

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("html-attribute-double-quotes"))
      end
    end

    context "with mixed double and single-quoted attributes" do
      let(:source) { '<div class="container" id=\'main\'>text</div>' }

      it "reports offense only for single-quoted attribute" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Attribute `id` uses single quotes")
      end
    end

    context "with empty double-quoted value" do
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

    context "when fixing a single-quoted attribute" do
      let(:source) { "<div class='container'>text</div>" }
      let(:expected) { '<div class="container">text</div>' }
      let(:node) do
        document.value.children.first.open_tag.children.find { |c| c.is_a?(Herb::AST::HTMLAttributeNode) }
      end

      it "replaces single quotes with double quotes" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a single-quoted attribute alongside a double-quoted one" do
      let(:source) { '<div class="container" id=\'main\'>text</div>' }
      let(:expected) { '<div class="container" id="main">text</div>' }
      let(:node) do
        document.value.children.first.open_tag.children.select { |c| c.is_a?(Herb::AST::HTMLAttributeNode) }.last
      end

      it "replaces single quotes with double quotes only on the single-quoted attribute" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing multiple single-quoted attributes" do
      let(:source) { "<div class='container' id='main'>text</div>" }
      let(:expected) { '<div class="container" id="main">text</div>' }
      let(:node) do
        document.value.children.first.open_tag.children.find { |c| c.is_a?(Herb::AST::HTMLAttributeNode) }
      end

      it "replaces single quotes with double quotes on the first attribute" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected.sub('id="main"', "id='main'"))
      end
    end
  end
end
