# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::LowercaseAttributes do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template) }
  let(:context) { instance_double(Herb::Lint::Context) }

  describe ".rule_name" do
    it "returns 'html/lowercase-attributes'" do
      expect(described_class.rule_name).to eq("html/lowercase-attributes")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Attribute names should be lowercase")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    context "when attribute name is lowercase" do
      let(:template) { '<div class="container">text</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when attribute name is uppercase" do
      let(:template) { '<div CLASS="container">text</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html/lowercase-attributes")
        expect(subject.first.message).to eq("Attribute name 'CLASS' should be lowercase")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when attribute name is mixed case" do
      let(:template) { '<div onClick="handler()">text</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Attribute name 'onClick' should be lowercase")
      end
    end

    context "when multiple attributes have uppercase letters" do
      let(:template) { '<div CLASS="container" ID="main">text</div>' }

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("html/lowercase-attributes"))
      end
    end

    context "with mixed lowercase and uppercase attributes" do
      let(:template) { '<div class="container" ID="main">text</div>' }

      it "reports offense only for uppercase attribute" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Attribute name 'ID' should be lowercase")
      end
    end

    context "with nested elements containing uppercase attributes" do
      let(:template) do
        <<~HTML
          <div class="outer">
            <span DATA-VALUE="test">text</span>
          </div>
        HTML
      end

      it "reports offense with correct line number" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end

    context "with boolean attribute in uppercase" do
      let(:template) { "<input DISABLED />" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Attribute name 'DISABLED' should be lowercase")
      end
    end

    context "with element that has no attributes" do
      let(:template) { "<div>text</div>" }

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end

    context "with data attributes in uppercase" do
      let(:template) { '<div DATA-TEST="value">text</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Attribute name 'DATA-TEST' should be lowercase")
      end
    end

    context "with aria attributes in uppercase" do
      let(:template) { '<button ARIA-LABEL="Close">X</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Attribute name 'ARIA-LABEL' should be lowercase")
      end
    end
  end
end
