# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::NoSpaceInTag do
  describe ".rule_name" do
    it "returns 'html-no-space-in-tag'" do
      expect(described_class.rule_name).to eq("html-no-space-in-tag")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow extra whitespace inside HTML tags")
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
    context "with tag and attribute with correct spacing (documentation example)" do
      let(:source) { '<div class="foo"></div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with void tag and correct spacing (documentation example)" do
      let(:source) { '<img src="/logo.png" alt="Logo">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with multiple attributes and correct spacing (documentation example)" do
      let(:source) { '<input class="foo" name="bar">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with tag and data attribute with correct spacing (documentation example)" do
      let(:source) { '<div class="foo" data-x="bar"></div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with correct multiline tag (documentation example)" do
      let(:source) do
        <<~HTML.chomp
          <div
            class="foo"
            data-x="bar"
          >
            foo
          </div>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "with extra space between tag name and first attribute (documentation example)" do
      let(:source) { '<div  class="foo"></div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Extra space detected where there should be a single space.")
      end
    end

    context "with trailing space before > (documentation example)" do
      let(:source) { '<div class="foo" ></div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Extra space detected where there should be no space.")
      end
    end

    context "with extra space between tag name and first attribute on void tag (documentation example)" do
      let(:source) { '<img  alt="Logo" src="/logo.png">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Extra space detected where there should be a single space.")
      end
    end

    context "with extra space between attributes (documentation example)" do
      let(:source) { '<div class="foo"      data-x="bar"></div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Extra space detected where there should be a single space.")
      end
    end

    context "with multiline tag with wrong indentation (documentation example)" do
      let(:source) do
        <<~HTML.chomp
          <div
             class="foo"
              data-x="bar"
          >
            foo
          </div>
        HTML
      end

      it "reports offenses for each wrongly indented attribute" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to all(eq("Extra space detected where there should be no space."))
      end
    end

    context "with space after tag name in open tag (documentation example)" do
      let(:source) { "<div >\n</  div>" }

      it "reports offenses for space in open and close tags" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to all(eq("Extra space detected where there should be no space."))
      end
    end

    # Additional edge cases
    context "when tags have no extra spaces" do
      let(:source) { "<div>content</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when self-closing tag has correct single space before />" do
      let(:source) { "<br />" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when correct multiline tag" do
      let(:source) do
        <<~HTML.chomp
          <input
            type="password"
            class="foo"
          >
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when tag contains ERB attribute (documentation example)" do
      let(:source) { "<input <%= attributes %>>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiline tag contains ERB attribute (documentation example)" do
      let(:source) do
        <<~HTML.chomp
          <input
            type="password"
            <%= attributes %>
          >
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when open tag has extra space before >" do
      let(:source) { "<div  >content</div>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Extra space detected where there should be no space.")
      end
    end

    context "when close tag has space after </" do
      let(:source) { "<div>content</   div>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Extra space detected where there should be no space.")
      end
    end

    context "when close tag has space after tag name" do
      let(:source) { "<div>content</div >" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Extra space detected where there should be no space.")
      end
    end

    context "when close tag has spaces both before and after tag name" do
      let(:source) { "<div>content</  div  >" }

      it "reports two offenses" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to all(eq("Extra space detected where there should be no space."))
      end
    end

    context "when self-closing tag has no space before />" do
      let(:source) { "<br/>" }

      it "reports an offense for missing space" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("No space detected where there should be a single space.")
      end
    end

    context "when self-closing tag with attribute has no space before />" do
      let(:source) { "<div class=\"foo\"/>" }

      it "reports an offense for missing space" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("No space detected where there should be a single space.")
      end
    end

    context "when extra space between tag name and end solidus" do
      let(:source) { "<br   />" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Extra space detected where there should be no space.")
      end
    end

    context "when extra space between last attribute and solidus" do
      let(:source) { '<br class="hide"   />' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Extra space detected where there should be no space.")
      end
    end

    context "when extra space between last attribute and end of tag" do
      let(:source) { '<img class="hide"    >' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Extra space detected where there should be no space.")
      end
    end

    context "when multiple spacing issues in one tag" do
      let(:source) { '<img   class="hide"    >' }

      it "reports offenses for each issue" do
        expect(subject.size).to eq(2)
        messages = subject.map(&:message)
        expect(messages).to include("Extra space detected where there should be a single space.")
        expect(messages).to include("Extra space detected where there should be no space.")
      end
    end

    context "when extra newline between tag name and first attribute" do
      let(:source) do
        <<~HTML.chomp
          <input

            type="password" />
        HTML
      end

      it "reports blank line and trailing space offenses" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to include(
          described_class::EXTRA_SPACE_SINGLE_BREAK,
          described_class::EXTRA_SPACE_NO_SPACE
        )
      end
    end

    context "when extra newline between tag name and end of tag" do
      let(:source) do
        <<~HTML.chomp
          <input

            />
        HTML
      end

      it "reports blank line and indentation offenses" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to include(
          described_class::EXTRA_SPACE_SINGLE_BREAK,
          described_class::EXTRA_SPACE_NO_SPACE
        )
      end
    end

    context "when extra newline between attributes" do
      let(:source) do
        <<~HTML.chomp
          <input
            type="password"

            class="foo" />
        HTML
      end

      it "reports blank line and trailing space offenses" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to include(
          described_class::EXTRA_SPACE_SINGLE_BREAK,
          described_class::EXTRA_SPACE_NO_SPACE
        )
      end
    end

    context "when end solidus is on newline with wrong indentation" do
      let(:source) do
        <<~HTML.chomp
          <input
            type="password"
            class="foo"
            />
        HTML
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Extra space detected where there should be no space.")
      end
    end

    context "when end of tag is on newline with wrong indentation" do
      let(:source) do
        <<~HTML.chomp
          <input
            type="password"
            class="foo"
            >
        HTML
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Extra space detected where there should be no space.")
      end
    end

    describe "location" do
      context "with correct location for open tag offense" do
        let(:source) { "<div  >content</div>" }

        it "reports the location of the whitespace gap" do
          expect(subject.first.line).to eq(1)
          expect(subject.first.column).to eq(4)
        end
      end

      context "with correct location for close tag offense" do
        let(:source) { "<div>content</  div>" }

        it "reports the location of the whitespace gap" do
          expect(subject.first.line).to eq(1)
          expect(subject.first.column).to eq(14)
        end
      end
    end
  end

  # Autofix is disabled (autocorrectable = false) to match TypeScript implementation
  # TODO: enable and fix autofix (matching TypeScript implementation)
  # See: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-space-in-tag.ts
end
