# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::NoDuplicateIds do
  describe ".rule_name" do
    it "returns 'html-no-duplicate-ids'" do
      expect(described_class.rule_name).to eq("html-no-duplicate-ids")
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
    subject { described_class.new(matcher:).check(document, context) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    # Good examples from documentation
    context "with unique ids (documentation example)" do
      let(:source) do
        <<~HTML
          <div id="header">Header</div>
          <div id="main-content">Main Content</div>
          <div id="footer">Footer</div>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with unique erb dom_id ids (documentation example)" do
      let(:source) do
        <<~ERB
          <div id="<%= dom_id("header") %>">Header</div>
          <div id="<%= dom_id("main_content") %>">Main Content</div>
          <div id="<%= dom_id("footer") %>">Footer</div>
        ERB
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "with duplicate id 'header' (documentation example)" do
      let(:source) do
        <<~HTML
          <div id="header">Header</div>

          <div id="header">Duplicate Header</div>

          <div id="footer">Footer</div>
        HTML
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-duplicate-ids")
        expect(subject.first.message).to include("Duplicate id 'header'")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "with duplicate erb dom_id ids (documentation example)" do
      let(:source) do
        <<~ERB
          <div id="<%= dom_id("header") %>">Header</div>

          <div id="<%= dom_id("header") %>">Duplicate Header</div>

          <div id="<%= dom_id("footer") %>">Footer</div>
        ERB
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-duplicate-ids")
        expect(subject.first.severity).to eq("error")
      end
    end

    # Additional edge case tests
    context "when the same id appears three times" do
      let(:source) do
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
      let(:source) { "<div>text</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when id attribute has empty value" do
      let(:source) do
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
      let(:source) do
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

    context "when id has mixed case (case-sensitive check)" do
      let(:source) do
        <<~HTML
          <div id="Content">First</div>
          <div id="content">Second</div>
        HTML
      end

      it "does not report an offense (ids are case-sensitive)" do
        expect(subject).to be_empty
      end
    end
  end
end
