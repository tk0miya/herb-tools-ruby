# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::NoBlockInsideInline do
  describe ".rule_name" do
    it "returns 'html-no-block-inside-inline'" do
      expect(described_class.rule_name).to eq("html-no-block-inside-inline")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow block-level elements nested inside inline elements")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    subject { described_class.new.check(document, context) }

    let(:document) { Herb.parse(source) }
    let(:context) { build(:context) }

    context "when block element is inside block element" do
      let(:source) { "<div><p>Hello</p></div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when inline element is inside block element" do
      let(:source) { "<div><span>Hello</span></div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when inline element is inside inline element" do
      let(:source) { "<span><strong>Hello</strong></span>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when block element is nested inside inline element" do
      let(:source) { "<span><div>Block in inline</div></span>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-block-inside-inline")
        expect(subject.first.message).to eq("Block-level element `<div>` must not be nested inside an inline element")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when block element is deeply nested inside inline element" do
      let(:source) do
        <<~HTML
          <span>
            <em>
              <div>Deep block</div>
            </em>
          </span>
        HTML
      end

      it "reports an offense for the block element" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-block-inside-inline")
        expect(subject.first.message).to eq("Block-level element `<div>` must not be nested inside an inline element")
      end
    end

    context "when multiple block elements are inside inline element" do
      let(:source) do
        <<~HTML
          <span>
            <div>First block</div>
            <p>Second block</p>
          </span>
        HTML
      end

      it "reports an offense for each block element" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("html-no-block-inside-inline"))
      end
    end

    context "when list is nested inside inline element" do
      let(:source) { "<span><ul><li>Item</li></ul></span>" }

      it "reports an offense for the list" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Block-level element `<ul>` must not be nested inside an inline element")
      end
    end

    context "when tags use uppercase" do
      let(:source) { "<SPAN><DIV>Block</DIV></SPAN>" }

      it "reports an offense (case insensitive)" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-block-inside-inline")
      end
    end

    context "with sibling elements without nesting violation" do
      let(:source) { "<span>Hello</span><div>World</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with block inside inline that is inside block" do
      let(:source) do
        <<~HTML
          <div>
            <span>
              <p>Block in inline in block</p>
            </span>
          </div>
        HTML
      end

      it "reports an offense for the inner block element" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Block-level element `<p>` must not be nested inside an inline element")
      end
    end

    context "with non-block non-inline elements" do
      let(:source) { "<custom-element><div>Block</div></custom-element>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with ERB content inside inline element" do
      let(:source) { "<span><%= content %></span>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with multiple inline parents" do
      let(:source) do
        <<~HTML
          <span>
            <div>First violation</div>
          </span>
          <em>
            <p>Second violation</p>
          </em>
        HTML
      end

      it "reports an offense for each violation" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("html-no-block-inside-inline"))
      end
    end
  end
end
