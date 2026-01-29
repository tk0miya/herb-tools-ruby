# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::A11y::IframeHasTitle do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template) }
  let(:context) { instance_double(Herb::Lint::Context) }

  describe ".rule_name" do
    it "returns 'a11y/iframe-has-title'" do
      expect(described_class.rule_name).to eq("a11y/iframe-has-title")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Require title attribute on iframe elements")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    context "when iframe has title attribute" do
      let(:template) { '<iframe src="content.html" title="Embedded content"></iframe>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when iframe is missing title attribute" do
      let(:template) { '<iframe src="content.html"></iframe>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("a11y/iframe-has-title")
        expect(subject.first.message).to eq("Missing or empty title attribute on iframe element")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when iframe has empty title attribute" do
      let(:template) { '<iframe src="content.html" title=""></iframe>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("a11y/iframe-has-title")
        expect(subject.first.message).to eq("Missing or empty title attribute on iframe element")
      end
    end

    context "when iframe has whitespace-only title attribute" do
      let(:template) { '<iframe src="content.html" title="   "></iframe>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when iframe has uppercase TITLE attribute" do
      let(:template) { '<iframe src="content.html" TITLE="Embedded content"></iframe>' }

      it "does not report an offense (case insensitive)" do
        expect(subject).to be_empty
      end
    end

    context "when IFRAME tag is uppercase" do
      let(:template) { '<IFRAME src="content.html"></IFRAME>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when multiple iframes are missing title" do
      let(:template) { '<iframe src="a.html"></iframe><iframe src="b.html"></iframe>' }

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("a11y/iframe-has-title"))
      end
    end

    context "with non-iframe elements" do
      let(:template) { '<div class="container"><p>Hello</p></div>' }

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end

    context "with mixed iframes on multiple lines" do
      let(:template) do
        <<~HTML
          <iframe src="a.html" title="First"></iframe>
          <iframe src="b.html"></iframe>
          <iframe src="c.html" title="Third"></iframe>
        HTML
      end

      it "reports offense only for iframe without title with correct line number" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end
  end
end
