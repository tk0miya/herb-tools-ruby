# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::NoEmptyHeadings do
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
    context "with heading with text content (documentation example)" do
      let(:source) { "<h1>Heading Content</h1>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with heading with nested span (documentation example)" do
      let(:source) { "<h1><span>Text</span></h1>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with aria heading with text content (documentation example)" do
      let(:source) { '<div role="heading" aria-level="1">Heading Content</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with heading with aria-hidden attribute (documentation example)" do
      let(:source) { '<h1 aria-hidden="true">Heading Content</h1>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with heading with hidden attribute (documentation example)" do
      let(:source) { "<h1 hidden>Heading Content</h1>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "with empty h1 (documentation example)" do
      let(:source) { "<h1></h1>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-empty-headings")
        expect(subject.first.message).to eq(
          "Heading element `<h1>` must not be empty. " \
          "Provide accessible text content for screen readers and SEO."
        )
        expect(subject.first.severity).to eq("error")
      end
    end

    context "with empty h2 (documentation example)" do
      let(:source) { "<h2></h2>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-empty-headings")
        expect(subject.first.message).to eq(
          "Heading element `<h2>` must not be empty. " \
          "Provide accessible text content for screen readers and SEO."
        )
        expect(subject.first.severity).to eq("error")
      end
    end

    context "with empty h3 (documentation example)" do
      let(:source) { "<h3></h3>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "with empty h4 (documentation example)" do
      let(:source) { "<h4></h4>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "with empty h5 (documentation example)" do
      let(:source) { "<h5></h5>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "with empty h6 (documentation example)" do
      let(:source) { "<h6></h6>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "with empty aria heading (documentation example)" do
      let(:source) { '<div role="heading" aria-level="1"></div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-empty-headings")
        expect(subject.first.message).to eq(
          'Heading element `<div role="heading">` must not be empty. ' \
          "Provide accessible text content for screen readers and SEO."
        )
        expect(subject.first.severity).to eq("error")
      end
    end

    context "with heading containing only aria-hidden child (documentation example)" do
      let(:source) { '<h1><span aria-hidden="true">Inaccessible text</span></h1>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-empty-headings")
        expect(subject.first.message).to eq(
          "Heading element `<h1>` must not be empty. " \
          "Provide accessible text content for screen readers and SEO."
        )
        expect(subject.first.severity).to eq("error")
      end
    end

    # Additional edge case tests
    context "when heading has ERB output content" do
      let(:source) { "<h2><%= title %></h2>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when heading has ERB html-safe output content" do
      let(:source) { "<h2><%== title %></h2>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when heading has ERB silent tag only" do
      let(:source) { "<h2><% foo %></h2>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when heading has ERB comment only" do
      let(:source) { "<h2><%# comment %></h2>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when heading has ERB silent tag with trim only" do
      let(:source) { "<h2><%- foo -%></h2>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when heading contains only an empty child element" do
      let(:source) { "<h1><span></span></h1>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when heading child has aria-hidden set to false" do
      let(:source) { '<h1><span aria-hidden="false">text</span></h1>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when heading has mixed accessible and inaccessible children" do
      let(:source) { '<h1><span aria-hidden="true">hidden</span><span>visible</span></h1>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when aria heading role attribute is uppercase" do
      let(:source) { '<div role="HEADING"></div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when heading contains only whitespace" do
      let(:source) { "<h2>   </h2>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-empty-headings")
        expect(subject.first.message).to eq(
          "Heading element `<h2>` must not be empty. " \
          "Provide accessible text content for screen readers and SEO."
        )
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

    context "with empty heading inside template element" do
      let(:source) { "<template><h1></h1></template>" }

      it "does not report an offense" do
        expect(subject).to be_empty
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
