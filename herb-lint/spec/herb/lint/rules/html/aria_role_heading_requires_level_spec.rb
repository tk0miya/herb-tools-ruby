# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::AriaRoleHeadingRequiresLevel do
  describe ".rule_name" do
    it "returns 'html-aria-role-heading-requires-level'" do
      expect(described_class.rule_name).to eq("html-aria-role-heading-requires-level")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Require aria-level on elements with role=\"heading\"")
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

    context "when element has role='heading' and aria-level" do
      let(:source) { '<div role="heading" aria-level="2">Title</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element has role='heading' without aria-level" do
      let(:source) { '<div role="heading">Title</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-aria-role-heading-requires-level")
        expect(subject.first.message).to eq("Element with `role=\"heading\"` must have an `aria-level` attribute.")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when element has a different role" do
      let(:source) { '<div role="button">Click</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element has no role attribute" do
      let(:source) { "<div>Content</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element has role='heading' with uppercase ARIA-LEVEL" do
      let(:source) { '<div role="heading" ARIA-LEVEL="3">Title</div>' }

      it "does not report an offense (case insensitive)" do
        expect(subject).to be_empty
      end
    end

    context "when element has uppercase ROLE='HEADING'" do
      let(:source) { '<div ROLE="HEADING">Title</div>' }

      it "reports an offense when aria-level is missing" do
        expect(subject.size).to eq(1)
      end
    end

    context "when multiple elements with role='heading' are missing aria-level" do
      let(:source) { '<div role="heading">A</div><span role="heading">B</span>' }

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("html-aria-role-heading-requires-level"))
      end
    end

    context "with non-heading elements" do
      let(:source) { '<p>Hello</p><span class="title">World</span>' }

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end

    context "with mixed elements on multiple lines" do
      let(:source) do
        <<~HTML
          <div role="heading" aria-level="1">First</div>
          <div role="heading">Second</div>
          <div role="heading" aria-level="3">Third</div>
        HTML
      end

      it "reports offense only for element without aria-level with correct line number" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end
  end
end
