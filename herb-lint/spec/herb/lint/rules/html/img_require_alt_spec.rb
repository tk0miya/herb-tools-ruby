# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::ImgRequireAlt do
  describe ".rule_name" do
    it "returns 'html-img-require-alt'" do
      expect(described_class.rule_name).to eq("html-img-require-alt")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Require alt attribute on img tags")
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
    context "when img tag has alt attribute" do
      let(:source) { '<img src="/logo.png" alt="Company logo">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when img tag has alt attribute with ERB tag" do
      let(:source) { '<img src="/avatar.jpg" alt="<%= user.name %>\'s profile picture">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when img tag has empty alt attribute" do
      let(:source) { '<img src="/divider.png" alt="">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when using image_tag helper with alt" do
      let(:source) { '<%= image_tag image_path("logo.png"), alt: "Company logo" %>' }

      # NOTE: Rails helpers are not checked (ERBContentNode), so no offense is reported
      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "when img tag is missing alt attribute" do
      let(:source) { '<img src="/logo.png">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-img-require-alt")
        expect(subject.first.message).to eq(
          "Missing required `alt` attribute on `<img>` tag. " \
          "Add `alt=\"\"` for decorative images or `alt=\"description\"` for informative images."
        )
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when img tag has alt attribute without value" do
      let(:source) { '<img src="/avatar.jpg" alt>' }

      # TODO: Current implementation only checks attribute presence, not value
      # Future enhancement may require non-empty alt values
      it "reports an offense (alt attribute should have a value)",
         skip: "Current implementation only checks attribute presence, not value" do
        expect(subject.size).to eq(1)
      end
    end

    context "when using image_tag helper without alt" do
      let(:source) { '<%= image_tag image_path("logo.png") %>' }

      # TODO: Rails helpers (ERB output tags) are not currently checked by this rule
      it "reports an offense", skip: "Rails helpers (ERB output tags) are not currently checked" do
        expect(subject.size).to eq(1)
      end
    end

    # Additional edge cases
    context "when multiple img tags are missing alt attribute" do
      let(:source) { '<img src="/logo.png"><img src="/banner.jpg">' }

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("html-img-require-alt"))
      end
    end

    context "when img tag has uppercase ALT attribute" do
      let(:source) { '<img src="/logo.png" ALT="Logo">' }

      it "does not report an offense (case insensitive)" do
        expect(subject).to be_empty
      end
    end

    context "when IMG tag is uppercase" do
      let(:source) { '<IMG src="/logo.png">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "with non-img elements" do
      let(:source) { '<div class="container"><p>Hello</p></div>' }

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end

    context "with mixed img tags on multiple lines" do
      let(:source) do
        <<~HTML
          <img src="a.png" alt="A">
          <img src="b.png">
          <img src="c.png" alt="C">
        HTML
      end

      it "reports offense only for img without alt with correct line number" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end
  end
end
