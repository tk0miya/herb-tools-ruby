# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::NoSelfClosing do
  describe ".rule_name" do
    it "returns 'html-no-self-closing'" do
      expect(described_class.rule_name).to eq("html-no-self-closing")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow self-closing syntax for HTML elements")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe ".safe_autofixable?" do
    it "returns true" do
      expect(described_class.safe_autofixable?).to be(true)
    end
  end

  describe "#check" do
    subject { described_class.new(matcher:).check(document, context) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    # Good examples from documentation
    context "with proper span with closing tag (documentation example)" do
      let(:source) { "<span></span>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with proper div with closing tag (documentation example)" do
      let(:source) { "<div></div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with void img without self-closing slash (documentation example)" do
      let(:source) { '<img src="/logo.png" alt="Logo">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with void input without self-closing slash (documentation example)" do
      let(:source) { '<input type="text" autocomplete="off">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with void br without self-closing slash (documentation example)" do
      let(:source) { "<br>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with void hr without self-closing slash (documentation example)" do
      let(:source) { "<hr>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "with self-closing span (documentation example)" do
      let(:source) { "<span />" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-self-closing")
        expect(subject.first.message).to eq(
          "Use `<span></span>` instead of self-closing `<span />` for HTML compatibility."
        )
        expect(subject.first.severity).to eq("error")
      end
    end

    context "with self-closing div (documentation example)" do
      let(:source) { "<div />" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-self-closing")
        expect(subject.first.message).to eq(
          "Use `<div></div>` instead of self-closing `<div />` for HTML compatibility."
        )
      end
    end

    context "with self-closing img with attributes (documentation example)" do
      let(:source) { '<img src="/logo.png" alt="Logo" />' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-self-closing")
        expect(subject.first.message).to eq("Use `<img>` instead of self-closing `<img />` for HTML compatibility.")
      end
    end

    context "with self-closing input (documentation example)" do
      let(:source) { '<input type="text" autocomplete="off" />' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-self-closing")
        expect(subject.first.message).to eq("Use `<input>` instead of self-closing `<input />` for HTML compatibility.")
      end
    end

    context "with self-closing br (documentation example)" do
      let(:source) { "<br />" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-self-closing")
        expect(subject.first.message).to eq("Use `<br>` instead of self-closing `<br />` for HTML compatibility.")
      end
    end

    context "with self-closing hr (documentation example)" do
      let(:source) { "<hr />" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-self-closing")
        expect(subject.first.message).to eq("Use `<hr>` instead of self-closing `<hr />` for HTML compatibility.")
      end
    end

    # Additional edge case tests
    context "when void element has self-closing slash without space" do
      let(:source) { "<br/>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-self-closing")
        expect(subject.first.message).to eq("Use `<br>` instead of self-closing `<br />` for HTML compatibility.")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when non-void element has closing tag" do
      let(:source) { "<div>content</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiple void elements have self-closing slashes" do
      let(:source) do
        <<~HTML
          <br/>
          <hr/>
          <img src="photo.jpg" />
        HTML
      end

      it "reports an offense for each" do
        expect(subject.size).to eq(3)
      end
    end

    context "when void element is nested inside non-void element" do
      let(:source) do
        <<~HTML
          <div>
            <img src="photo.jpg" />
          </div>
        HTML
      end

      it "reports an offense for the nested void element" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end
  end

  describe "#autofix" do
    subject { described_class.new(matcher:).autofix(node, document) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:node) { document.value.children.first }

    context "when fixing self-closing br tag" do
      let(:source) { "<br/>" }
      let(:expected) { "<br>" }

      it "removes the self-closing slash" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing self-closing br tag with space" do
      let(:source) { "<br />" }
      let(:expected) { "<br>" }

      it "removes the self-closing slash and trailing whitespace" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing self-closing img tag with attributes" do
      let(:source) { '<img src="photo.jpg" />' }
      let(:expected) { '<img src="photo.jpg">' }

      it "removes the self-closing slash while preserving attributes" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end
  end
end
