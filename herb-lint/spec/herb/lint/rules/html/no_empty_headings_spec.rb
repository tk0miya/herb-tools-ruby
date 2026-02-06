# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HtmlNoEmptyHeadings do
  describe ".rule_name" do
    it "returns 'html-no-empty-headings'" do
      expect(described_class.rule_name).to eq("html-no-empty-headings")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Heading elements must not be empty")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    subject { described_class.new.check(document, context) }

    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    context "when heading has text content" do
      let(:source) { "<h1>Page Title</h1>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when heading has ERB content" do
      let(:source) { "<h2><%= title %></h2>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when heading has nested element" do
      let(:source) { "<h3><span>Hello</span></h3>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when heading is empty" do
      let(:source) { "<h1></h1>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-empty-headings")
        expect(subject.first.message).to eq("Heading element `<h1>` must not be empty")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when heading contains only whitespace" do
      let(:source) { "<h2>   </h2>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-empty-headings")
        expect(subject.first.message).to eq("Heading element `<h2>` must not be empty")
      end
    end

    context "when multiple empty headings exist" do
      let(:source) { "<h1></h1><h2></h2><h3></h3>" }

      it "reports an offense for each" do
        expect(subject.size).to eq(3)
        expect(subject.map(&:rule_name)).to all(eq("html-no-empty-headings"))
      end
    end

    context "when heading tag is uppercase" do
      let(:source) { "<H1></H1>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "with non-heading elements" do
      let(:source) { "<div></div><p></p><span></span>" }

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end

    context "with mixed headings on multiple lines" do
      let(:source) do
        <<~HTML
          <h1>Page Title</h1>
          <h2></h2>
          <h3>Section</h3>
        HTML
      end

      it "reports offense only for empty heading with correct line number" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end

    context "when heading has text with surrounding whitespace" do
      let(:source) { "<h1>  Hello  </h1>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end
  end
end
