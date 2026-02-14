# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::NavigationHasLabel do
  describe ".rule_name" do
    it "returns 'html-navigation-has-label'" do
      expect(described_class.rule_name).to eq("html-navigation-has-label")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Require accessible label on nav elements")
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
    context "when nav has aria-label (documentation example)" do
      let(:source) do
        <<~HTML
          <nav aria-label="Main navigation">
            <ul>
              <li><a href="/">Home</a></li>
              <li><a href="/about">About</a></li>
            </ul>
          </nav>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when nav has aria-labelledby (documentation example)" do
      let(:source) do
        <<~HTML
          <nav aria-labelledby="breadcrumb-title">
            <h2 id="breadcrumb-title">Breadcrumb</h2>
            <ol>
              <li><a href="/">Home</a></li>
              <li>Current Page</li>
            </ol>
          </nav>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when div with role=navigation has aria-label (documentation example)" do
      let(:source) do
        <<~HTML
          <div role="navigation" aria-label="Footer links">
            <a href="/privacy">Privacy</a>
            <a href="/terms">Terms</a>
          </div>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "when nav is missing label (documentation example)" do
      let(:source) do
        <<~HTML
          <nav>
            <ul>
              <li><a href="/">Home</a></li>
              <li><a href="/about">About</a></li>
            </ul>
          </nav>
        HTML
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-navigation-has-label")
        expect(subject.first.message)
          .to eq("The navigation landmark should have a unique accessible name via `aria-label` or `aria-labelledby`")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when div with role=navigation is missing label (documentation example)" do
      let(:source) do
        <<~HTML
          <div role="navigation">
            <a href="/privacy">Privacy</a>
            <a href="/terms">Terms</a>
          </div>
        HTML
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-navigation-has-label")
        expect(subject.first.message).to eq(
          "The navigation landmark should have a unique accessible name via `aria-label` or `aria-labelledby`. " \
          "Consider replacing `role=\"navigation\"` with a native `<nav>` element."
        )
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when nav has empty aria-label" do
      let(:source) { '<nav aria-label=""><a href="/">Home</a></nav>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-navigation-has-label")
      end
    end

    context "when nav has whitespace-only aria-label" do
      let(:source) { '<nav aria-label="   "><a href="/">Home</a></nav>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when nav has empty aria-labelledby" do
      let(:source) { '<nav aria-labelledby=""><a href="/">Home</a></nav>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when nav has uppercase ARIA-LABEL attribute" do
      let(:source) { '<nav ARIA-LABEL="Main navigation"><a href="/">Home</a></nav>' }

      it "does not report an offense (case insensitive)" do
        expect(subject).to be_empty
      end
    end

    context "when NAV tag is uppercase" do
      let(:source) { '<NAV><a href="/">Home</a></NAV>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when multiple navs are missing labels" do
      let(:source) { '<nav><a href="/">Home</a></nav><nav><a href="/about">About</a></nav>' }

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("html-navigation-has-label"))
      end
    end

    context "with non-nav elements" do
      let(:source) { '<div class="container"><p>Hello</p></div>' }

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end

    context "with mixed navs on multiple lines" do
      let(:source) do
        <<~HTML
          <nav aria-label="Main navigation"><a href="/">Home</a></nav>
          <nav><a href="/about">About</a></nav>
          <nav aria-labelledby="footer-nav"><a href="/contact">Contact</a></nav>
        HTML
      end

      it "reports offense only for nav without label with correct line number" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end
  end
end
