# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HtmlNoNestedLinks do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template, track_whitespace: true) }
  let(:context) { build(:context) }

  describe ".rule_name" do
    it "returns 'html-no-nested-links'" do
      expect(described_class.rule_name).to eq("html-no-nested-links")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow nesting of anchor elements")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    context "when anchor is not nested" do
      let(:template) { '<a href="/page">Link</a>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiple anchors are siblings" do
      let(:template) { '<a href="/first">First</a><a href="/second">Second</a>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when anchor is nested inside another anchor" do
      let(:template) do
        <<~HTML
          <a href="/outer">
            <a href="/inner">Nested link</a>
          </a>
        HTML
      end

      it "reports an offense for the inner anchor" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-nested-links")
        expect(subject.first.message).to eq("Nested anchor element found inside another anchor element")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when anchor is deeply nested inside another anchor" do
      let(:template) do
        <<~HTML
          <a href="/outer">
            <div>
              <span>
                <a href="/inner">Deep nested link</a>
              </span>
            </div>
          </a>
        HTML
      end

      it "reports an offense for the deeply nested anchor" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-nested-links")
      end
    end

    context "when multiple anchors are nested" do
      let(:template) do
        <<~HTML
          <a href="/outer">
            <a href="/inner1">First nested</a>
            <a href="/inner2">Second nested</a>
          </a>
        HTML
      end

      it "reports an offense for each nested anchor" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("html-no-nested-links"))
      end
    end

    context "when anchors are triply nested" do
      let(:template) do
        <<~HTML
          <a href="/outer">
            <a href="/middle">
              <a href="/inner">Innermost</a>
            </a>
          </a>
        HTML
      end

      it "reports an offense for each nested level" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("html-no-nested-links"))
      end
    end

    context "when anchor tags use uppercase" do
      let(:template) do
        <<~HTML
          <A href="/outer">
            <A href="/inner">Nested</A>
          </A>
        HTML
      end

      it "reports an offense (case insensitive)" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-nested-links")
      end
    end

    context "with non-anchor elements" do
      let(:template) { "<div><span>Hello</span></div>" }

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end

    context "when anchors are inside different parent elements" do
      let(:template) do
        <<~HTML
          <div><a href="/first">First</a></div>
          <div><a href="/second">Second</a></div>
        HTML
      end

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end
  end
end
