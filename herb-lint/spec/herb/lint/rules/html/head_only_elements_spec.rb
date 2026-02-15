# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::HeadOnlyElements do
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
    subject { described_class.new(matcher:).check(document, context) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source) }
    let(:context) { build(:context) }

    # Good examples from documentation
    context "when standard head structure with meta, link, title" do
      let(:source) do
        <<~HTML
          <head>
            <title>My Page</title>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <link rel="stylesheet" href="/styles.css">
          </head>

          <body>
            <h1>Welcome</h1>
          </body>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when title is inside svg element" do
      let(:source) do
        <<~HTML
          <body>
            <svg>
              <title>Chart Title</title>
              <rect width="100" height="100" />
            </svg>
          </body>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when style is inside svg element" do
      let(:source) do
        <<~HTML
          <body>
            <svg>
              <style>.bar { fill: blue; }</style>
              <rect width="100" height="100" />
            </svg>
          </body>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when meta has itemprop attribute for microdata" do
      let(:source) do
        <<~HTML
          <body>
            <div itemscope itemtype="https://schema.org/Book">
              <span itemprop="name">The Hobbit</span>
              <meta itemprop="author" content="J.R.R. Tolkien">
              <meta itemprop="isbn" content="978-0618260300">
            </div>
          </body>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "when head elements are in body with blank lines" do
      let(:source) do
        <<~HTML
          <body>
            <title>My Page</title>

            <meta charset="UTF-8">

            <link rel="stylesheet" href="/styles.css">

            <h1>Welcome</h1>
          </body>
        HTML
      end

      it "reports an offense for each head element" do
        expect(subject.size).to eq(3)
        offenses = subject.map(&:rule_name)
        expect(offenses).to all(eq("html-head-only-elements"))
      end
    end

    context "when title with Rails helper is in body" do
      let(:source) do
        <<~HTML
          <body>
            <title><%= content_for?(:title) ? yield(:title) : "Default Title" %></title>
          </body>
        HTML
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Element `<title>` must be placed inside the `<head>` tag.")
      end
    end

    context "when regular meta tags are in body" do
      let(:source) do
        <<~HTML
          <body>
            <meta name="description" content="Page description">
            <meta charset="UTF-8">
            <meta http-equiv="refresh" content="30">
          </body>
        HTML
      end

      it "reports an offense for each meta tag" do
        expect(subject.size).to eq(3)
        expect(subject.map(&:message)).to all(eq("Element `<meta>` must be placed inside the `<head>` tag."))
      end
    end

    # Additional edge cases
    context "when head-only element is outside head" do
      let(:source) { "<body><title>Page Title</title></body>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-head-only-elements")
        expect(subject.first.message).to eq("Element `<title>` must be placed inside the `<head>` tag.")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when head-only element appears at top level without head or body" do
      let(:source) { "<title>Page Title</title>" }

      it "does not report an offense (not inside body)" do
        expect(subject).to be_empty
      end
    end

    context "when head-only element is deeply nested outside head" do
      let(:source) do
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
        expect(subject.first.message).to eq("Element `<title>` must be placed inside the `<head>` tag.")
      end
    end

    context "when head-only elements use uppercase tags" do
      let(:source) { "<BODY><TITLE>Page Title</TITLE></BODY>" }

      it "reports an offense (case insensitive)" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-head-only-elements")
      end
    end

    context "when non-head-only elements are outside head" do
      let(:source) { "<body><div>Content</div><p>Text</p></body>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when head-only element is in head and also in body" do
      let(:source) do
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
        expect(subject.first.message).to eq("Element `<title>` must be placed inside the `<head>` tag.")
      end
    end
  end
end
