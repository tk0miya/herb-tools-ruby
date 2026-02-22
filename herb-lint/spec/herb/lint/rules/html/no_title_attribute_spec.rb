# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::NoTitleAttribute do
  describe ".rule_name" do
    it "returns 'html-no-title-attribute'" do
      expect(described_class.rule_name).to eq("html-no-title-attribute")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow use of `title` attribute")
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
    context "with visible text instead of title (documentation example)" do
      let(:source) { "<button>Save document</button>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with aria-label instead of title (documentation example)" do
      let(:source) { '<button aria-label="Close dialog">×</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with title on iframe (exception, documentation example)" do
      let(:source) { '<iframe src="https://example.com" title="Example website content"></iframe>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with title on link (exception, documentation example)" do
      let(:source) { '<link href="default.css" rel="stylesheet" title="Default Style">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "with title on button (documentation example)" do
      let(:source) { '<button title="Save your changes">Save</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-title-attribute")
        expect(subject.first.message).to eq(
          "Avoid using the 'title' attribute; it is unreliable for screen readers and touch devices"
        )
        expect(subject.first.severity).to eq("error")
      end
    end

    context "with title on div (documentation example)" do
      let(:source) { '<div title="This is important information">Content</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-title-attribute")
      end
    end

    context "with title on span (documentation example)" do
      let(:source) { '<span title="Required field">*</span>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-title-attribute")
      end
    end

    context "with title on input (documentation example)" do
      let(:source) { '<input type="text" title="Enter your name" autocomplete="off">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-title-attribute")
      end
    end

    # Additional edge case tests
    context "when element has no title attribute" do
      let(:source) { '<span class="info">More info available</span>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element has a title attribute with uppercase name" do
      let(:source) { '<span TITLE="More info">Hover me</span>' }

      it "reports an offense (case-insensitive)" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-title-attribute")
      end
    end

    context "when multiple elements have title attributes" do
      let(:source) do
        <<~HTML
          <span title="Info 1">Text 1</span>
          <div title="Info 2">Text 2</div>
        HTML
      end

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
      end
    end

    context "when element has title attribute with empty value" do
      let(:source) { '<span title="">Hover me</span>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when element has other attributes but no title" do
      let(:source) { '<div class="container" id="main">text</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element has no attributes" do
      let(:source) { "<div>text</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element has both title and other attributes" do
      let(:source) { '<a href="/page" title="Go to page">Link</a>' }

      it "reports an offense only for the title attribute" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-title-attribute")
      end
    end

    context "with nested elements where only inner has title" do
      let(:source) do
        <<~HTML
          <div>
            <span title="tooltip">text</span>
          </div>
        HTML
      end

      it "reports an offense for the inner element" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end

    context "when attribute value contains 'title' but attribute name is not title" do
      let(:source) { '<div data-label="title">text</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end
  end
end
