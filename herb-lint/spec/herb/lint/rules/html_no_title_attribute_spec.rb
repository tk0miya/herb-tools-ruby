# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HtmlNoTitleAttribute do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template) }
  let(:context) { instance_double(Herb::Lint::Context) }

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
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    context "when element has no title attribute" do
      let(:template) { '<span class="info">More info available</span>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element has a title attribute" do
      let(:template) { '<span title="More info">Hover me</span>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-title-attribute")
        expect(subject.first.message).to eq(
          "Avoid using the 'title' attribute; it is unreliable for screen readers and touch devices"
        )
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when element has a title attribute with uppercase name" do
      let(:template) { '<span TITLE="More info">Hover me</span>' }

      it "reports an offense (case-insensitive)" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-title-attribute")
      end
    end

    context "when multiple elements have title attributes" do
      let(:template) do
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
      let(:template) { '<span title="">Hover me</span>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when element has other attributes but no title" do
      let(:template) { '<div class="container" id="main">text</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element has no attributes" do
      let(:template) { "<div>text</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element has both title and other attributes" do
      let(:template) { '<a href="/page" title="Go to page">Link</a>' }

      it "reports an offense only for the title attribute" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-title-attribute")
      end
    end

    context "with nested elements where only inner has title" do
      let(:template) do
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
      let(:template) { '<div data-label="title">text</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end
  end
end
