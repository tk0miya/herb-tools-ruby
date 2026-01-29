# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::LowercaseTags do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template) }
  let(:context) { instance_double(Herb::Lint::Context) }

  describe ".rule_name" do
    it "returns 'html/lowercase-tags'" do
      expect(described_class.rule_name).to eq("html/lowercase-tags")
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

  describe "#check" do
    context "when tag names are lowercase" do
      let(:template) { "<div>text</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when open tag has uppercase letters" do
      let(:template) { "<DIV>text</div>" }

      it "reports an offense for the open tag" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html/lowercase-tags")
        expect(subject.first.message).to eq("Tag name 'DIV' should be lowercase")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when close tag has uppercase letters" do
      let(:template) { "<div>text</DIV>" }

      it "reports an offense for the close tag" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html/lowercase-tags")
        expect(subject.first.message).to eq("Tag name 'DIV' should be lowercase")
      end
    end

    context "when both open and close tags have uppercase letters" do
      let(:template) { "<DIV>text</DIV>" }

      it "reports offenses for both tags" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to all(include("should be lowercase"))
      end
    end

    context "when tag has mixed case" do
      let(:template) { "<Div>text</Div>" }

      it "reports offenses for mixed case tags" do
        expect(subject.size).to eq(2)
        expect(subject.first.message).to eq("Tag name 'Div' should be lowercase")
      end
    end

    context "with multiple elements" do
      let(:template) do
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
      let(:template) do
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
      let(:template) { "<BR>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Tag name 'BR' should be lowercase")
      end
    end

    context "with void element in lowercase" do
      let(:template) { "<br>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end
  end
end
