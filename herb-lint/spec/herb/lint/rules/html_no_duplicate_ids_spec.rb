# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HtmlNoDuplicateIds do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template) }
  let(:context) { instance_double(Herb::Lint::Context) }

  describe ".rule_name" do
    it "returns 'html/no-duplicate-id'" do
      expect(described_class.rule_name).to eq("html/no-duplicate-id")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow duplicate id attribute values")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    context "when all ids are unique" do
      let(:template) do
        <<~HTML
          <div id="header">Header</div>
          <div id="content">Content</div>
          <div id="footer">Footer</div>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when there are duplicate ids" do
      let(:template) do
        <<~HTML
          <div id="content">First</div>
          <div id="content">Second</div>
        HTML
      end

      it "reports an offense for the duplicate with first occurrence line number" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html/no-duplicate-id")
        expect(subject.first.message).to include("Duplicate id 'content'")
        expect(subject.first.message).to include("first defined at line 1")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when the same id appears three times" do
      let(:template) do
        <<~HTML
          <div id="nav">First</div>
          <div id="nav">Second</div>
          <div id="nav">Third</div>
        HTML
      end

      it "reports an offense for each duplicate" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to all(include("Duplicate id 'nav'"))
      end
    end

    context "when elements have no id attribute" do
      let(:template) { "<div>text</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when id attribute has empty value" do
      let(:template) do
        <<~HTML
          <div id="">First</div>
          <div id="">Second</div>
        HTML
      end

      it "does not report an offense (empty ids are not tracked)" do
        expect(subject).to be_empty
      end
    end

    context "with nested elements having duplicate ids" do
      let(:template) do
        <<~HTML
          <div id="container">
            <span id="item">text</span>
            <span id="item">more text</span>
          </div>
        HTML
      end

      it "reports an offense for the nested duplicate with correct line number" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Duplicate id 'item'")
        expect(subject.first.line).to eq(3)
      end
    end

    context "with different ids on same tag type" do
      let(:template) do
        <<~HTML
          <div id="first">First</div>
          <div id="second">Second</div>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when id has mixed case (case-sensitive check)" do
      let(:template) do
        <<~HTML
          <div id="Content">First</div>
          <div id="content">Second</div>
        HTML
      end

      it "does not report an offense (ids are case-sensitive)" do
        expect(subject).to be_empty
      end
    end

    context "with single element having an id" do
      let(:template) { '<div id="unique">text</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end
  end
end
