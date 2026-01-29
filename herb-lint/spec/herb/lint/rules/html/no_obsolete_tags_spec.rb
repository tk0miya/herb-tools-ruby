# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::NoObsoleteTags do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template) }
  let(:context) { instance_double(Herb::Lint::Context) }

  describe ".rule_name" do
    it "returns 'html/no-obsolete-tags'" do
      expect(described_class.rule_name).to eq("html/no-obsolete-tags")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow obsolete HTML tags")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "OBSOLETE_TAGS" do
    it "contains all 25 obsolete tags" do
      expected_tags = %w[
        acronym applet basefont big blink center dir font frame frameset
        isindex keygen listing marquee menuitem multicol nextid nobr
        noembed noframes plaintext spacer strike tt xmp
      ]
      expect(described_class::OBSOLETE_TAGS).to match_array(expected_tags)
    end
  end

  describe "#check" do
    context "when using a modern HTML tag" do
      let(:template) { "<div>Content</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when using an obsolete tag" do
      let(:template) { "<center>Centered text</center>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html/no-obsolete-tags")
        expect(subject.first.message).to eq("The <center> tag is obsolete and should not be used")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when using uppercase obsolete tag" do
      let(:template) { "<CENTER>Centered</CENTER>" }

      it "reports an offense with lowercased tag name in message" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("The <center> tag is obsolete and should not be used")
      end
    end

    context "when multiple obsolete tags are used" do
      let(:template) do
        <<~HTML
          <center>Centered</center>
          <font color="red">Red</font>
        HTML
      end

      it "reports an offense for each obsolete tag" do
        expect(subject.size).to eq(2)
      end
    end

    context "when obsolete tag is nested inside modern tag" do
      let(:template) do
        <<~HTML
          <div>
            <center>Centered</center>
          </div>
        HTML
      end

      it "reports an offense for the obsolete tag" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("The <center> tag is obsolete and should not be used")
      end
    end

    context "when using valid HTML5 tags" do
      let(:template) do
        <<~HTML
          <header>Header</header>
          <nav>Navigation</nav>
          <main>Main content</main>
          <footer>Footer</footer>
        HTML
      end

      it "does not report any offenses" do
        expect(subject).to be_empty
      end
    end
  end
end
