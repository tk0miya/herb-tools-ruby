# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HtmlNoDuplicateAttributes do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template) }
  let(:context) { build(:context) }

  describe ".rule_name" do
    it "returns 'html-no-duplicate-attributes'" do
      expect(described_class.rule_name).to eq("html-no-duplicate-attributes")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow duplicate attributes on the same element")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    context "when there are no duplicate attributes" do
      let(:template) { '<div class="foo" id="bar">content</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when there are duplicate attributes" do
      let(:template) { '<div class="foo" class="bar">content</div>' }

      it "reports an offense for the duplicate" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-duplicate-attributes")
        expect(subject.first.message).to eq("Duplicate attribute 'class'")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when the same attribute appears three times" do
      let(:template) { '<div class="a" class="b" class="c">content</div>' }

      it "reports an offense for each duplicate" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to all(eq("Duplicate attribute 'class'"))
      end
    end

    context "when there are multiple different duplicate attributes" do
      let(:template) { '<div class="a" id="x" class="b" id="y">content</div>' }

      it "reports an offense for each duplicate" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to contain_exactly(
          "Duplicate attribute 'class'",
          "Duplicate attribute 'id'"
        )
      end
    end

    context "with attributes having different cases" do
      let(:template) { '<div CLASS="foo" class="bar">content</div>' }

      it "reports an offense (case-insensitive check)" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Duplicate attribute 'class'")
      end
    end

    context "with self-closing element having duplicate attributes" do
      let(:template) { '<input type="text" type="number">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Duplicate attribute 'type'")
      end
    end

    context "with nested elements having separate duplicates" do
      let(:template) do
        <<~HTML
          <div class="a" class="b">
            <span class="c" class="d">text</span>
          </div>
        HTML
      end

      it "reports an offense for each element" do
        expect(subject.size).to eq(2)
      end
    end

    context "with element having no attributes" do
      let(:template) { "<div>text</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with boolean attributes not duplicated" do
      let(:template) { "<input disabled readonly>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with duplicate boolean attributes" do
      let(:template) { "<input disabled disabled>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Duplicate attribute 'disabled'")
      end
    end

    context "with data attributes not duplicated" do
      let(:template) { '<div data-id="1" data-name="foo">text</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with duplicate data attributes" do
      let(:template) { '<div data-id="1" data-id="2">text</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Duplicate attribute 'data-id'")
      end
    end
  end
end
