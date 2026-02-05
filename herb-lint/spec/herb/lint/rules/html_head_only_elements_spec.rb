# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HtmlHeadOnlyElements do
  describe ".rule_name" do
    it "returns 'html-head-only-elements'" do
      expect(described_class.rule_name).to eq("html-head-only-elements")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow head-only elements outside of <head>")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    subject { described_class.new.check(document, context) }

    let(:document) { Herb.parse(template) }
    let(:context) { build(:context) }

    context "when head-only elements are inside head" do
      let(:template) do
        <<~HTML
          <head>
            <title>Page Title</title>
            <meta charset="utf-8">
            <link rel="stylesheet" href="style.css">
            <base href="/">
          </head>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when head-only element is outside head" do
      let(:template) { "<body><title>Page Title</title></body>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-head-only-elements")
        expect(subject.first.message).to eq("`<title>` element should only appear inside `<head>`")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when head-only element appears at top level without head" do
      let(:template) { "<title>Page Title</title>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-head-only-elements")
      end
    end

    context "when multiple head-only elements are outside head" do
      let(:template) do
        <<~HTML
          <body>
            <title>Page Title</title>
            <meta charset="utf-8">
            <link rel="stylesheet" href="style.css">
          </body>
        HTML
      end

      it "reports an offense for each element" do
        expect(subject.size).to eq(3)
        expect(subject.map(&:rule_name)).to all(eq("html-head-only-elements"))
      end
    end

    context "when head-only element is deeply nested outside head" do
      let(:template) do
        <<~HTML
          <body>
            <div>
              <span>
                <title>Nested Title</title>
              </span>
            </div>
          </body>
        HTML
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("`<title>` element should only appear inside `<head>`")
      end
    end

    context "when head-only elements use uppercase tags" do
      let(:template) { "<BODY><TITLE>Page Title</TITLE></BODY>" }

      it "reports an offense (case insensitive)" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-head-only-elements")
      end
    end

    context "when non-head-only elements are outside head" do
      let(:template) { "<body><div>Content</div><p>Text</p></body>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when document has both head and body sections" do
      let(:template) do
        <<~HTML
          <head>
            <title>Page Title</title>
            <meta charset="utf-8">
          </head>
          <body>
            <div>Content</div>
          </body>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when head-only element is in head and also in body" do
      let(:template) do
        <<~HTML
          <head>
            <title>Page Title</title>
          </head>
          <body>
            <title>Duplicate Title</title>
          </body>
        HTML
      end

      it "reports an offense only for the one outside head" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("`<title>` element should only appear inside `<head>`")
      end
    end
  end
end
