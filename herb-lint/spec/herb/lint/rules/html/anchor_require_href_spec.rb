# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HtmlAnchorRequireHref do
  describe ".rule_name" do
    it "returns 'html-anchor-require-href'" do
      expect(described_class.rule_name).to eq("html-anchor-require-href")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Require href attribute on anchor elements")
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

    context "when anchor has href attribute" do
      let(:source) { '<a href="/page">Click here</a>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when anchor has href with hash" do
      let(:source) { '<a href="#">Click here</a>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when anchor has empty href attribute" do
      let(:source) { '<a href="">Click here</a>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when anchor is missing href attribute" do
      let(:source) { "<a>Click here</a>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-anchor-require-href")
        expect(subject.first.message).to eq("Missing href attribute on anchor element")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when anchor has name but no href" do
      let(:source) { '<a name="anchor">Section</a>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-anchor-require-href")
      end
    end

    context "when multiple anchors are missing href" do
      let(:source) { "<a>First</a><a>Second</a>" }

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("html-anchor-require-href"))
      end
    end

    context "when anchor has uppercase HREF attribute" do
      let(:source) { '<a HREF="/page">Click here</a>' }

      it "does not report an offense (case insensitive)" do
        expect(subject).to be_empty
      end
    end

    context "when A tag is uppercase" do
      let(:source) { "<A>Click here</A>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "with non-anchor elements" do
      let(:source) { '<div class="container"><p>Hello</p></div>' }

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end

    context "with mixed anchors on multiple lines" do
      let(:source) do
        <<~HTML
          <a href="/first">First</a>
          <a>Second</a>
          <a href="/third">Third</a>
        HTML
      end

      it "reports offense only for anchor without href with correct line number" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end
  end
end
