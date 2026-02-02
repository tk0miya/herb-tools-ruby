# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HtmlAttributeEqualsSpacing do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template, track_whitespace: true) }
  let(:context) { build(:context) }

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

  describe "#check" do
    context "when attribute has no spaces around =" do
      let(:template) { '<div class="foo">text</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when attribute has space before =" do
      let(:template) { '<div class ="foo">text</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-attribute-equals-spacing")
        expect(subject.first.message).to eq("Unexpected space before `=` in attribute assignment")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when attribute has space after =" do
      let(:template) { '<div class= "foo">text</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Unexpected space after `=` in attribute assignment")
      end
    end

    context "when attribute has spaces on both sides of =" do
      let(:template) { '<div class = "foo">text</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Unexpected spaces around `=` in attribute assignment")
      end
    end

    context "when boolean attribute has no value" do
      let(:template) { "<input disabled>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiple attributes have spacing issues" do
      let(:template) { '<div class ="foo" id = "bar">text</div>' }

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("html-attribute-equals-spacing"))
      end
    end

    context "with mixed valid and invalid attributes" do
      let(:template) { '<div class="foo" id ="bar">text</div>' }

      it "reports offense only for the invalid attribute" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Unexpected space before `=` in attribute assignment")
      end
    end

    context "with nested elements having spacing issues" do
      let(:template) do
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
      let(:template) { "<div>text</div>" }

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end

    context "with multiple boolean attributes" do
      let(:template) { "<input disabled checked readonly>" }

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end
  end
end
