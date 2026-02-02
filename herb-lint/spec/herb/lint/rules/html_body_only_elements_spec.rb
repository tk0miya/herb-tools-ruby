# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HtmlBodyOnlyElements do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template) }
  let(:context) { build(:context) }

  describe ".rule_name" do
    it "returns 'html-body-only-elements'" do
      expect(described_class.rule_name).to eq("html-body-only-elements")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Certain elements should only appear inside `<body>`")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    context "when body-only element is inside body" do
      let(:template) do
        <<~HTML
          <body>
            <div>Content in body</div>
          </body>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when body-only element is inside head" do
      let(:template) do
        <<~HTML
          <head>
            <div>Content in head</div>
          </head>
        HTML
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-body-only-elements")
        expect(subject.first.message).to eq("Element `<div>` must be placed inside the `<body>` tag.")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when multiple body-only elements are inside head" do
      let(:template) do
        <<~HTML
          <head>
            <p>Paragraph</p>
            <div>Division</div>
            <main>Main content</main>
          </head>
        HTML
      end

      it "reports an offense for each element" do
        expect(subject.size).to eq(3)
        expect(subject.map(&:rule_name)).to all(eq("html-body-only-elements"))
        expect(subject.map(&:message)).to eq(
          [
            "Element `<p>` must be placed inside the `<body>` tag.",
            "Element `<div>` must be placed inside the `<body>` tag.",
            "Element `<main>` must be placed inside the `<body>` tag."
          ]
        )
      end
    end

    context "when head-only elements are inside head" do
      let(:template) do
        <<~HTML
          <head>
            <title>Page Title</title>
            <meta charset="utf-8">
            <link rel="stylesheet" href="style.css">
            <style>body { color: red; }</style>
            <base href="/">
          </head>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when head-and-body elements are inside head" do
      let(:template) do
        <<~HTML
          <head>
            <script src="app.js"></script>
            <noscript>Enable JavaScript</noscript>
            <template></template>
          </head>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when body-only element is deeply nested inside head" do
      let(:template) do
        <<~HTML
          <html>
            <head>
              <noscript>
                <p>Please enable JavaScript</p>
              </noscript>
            </head>
          </html>
        HTML
      end

      it "reports an offense for the deeply nested element" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Element `<p>` must be placed inside the `<body>` tag.")
      end
    end

    context "when body-only element uses uppercase tag name" do
      let(:template) do
        <<~HTML
          <HEAD>
            <DIV>Content</DIV>
          </HEAD>
        HTML
      end

      it "reports an offense (case insensitive)" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Element `<div>` must be placed inside the `<body>` tag.")
      end
    end

    context "when element is outside both head and body" do
      let(:template) { "<div>Content outside</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when there is a complete document structure" do
      let(:template) do
        <<~HTML
          <html>
            <head>
              <title>Page</title>
            </head>
            <body>
              <div>Content</div>
            </body>
          </html>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end
  end
end
