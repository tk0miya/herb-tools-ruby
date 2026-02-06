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
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    subject { described_class.new.check(document, context) }

    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    describe "when space is correct" do
      context "when tags have no extra spaces" do
        let(:source) { "<div>content</div>" }

        it "does not report an offense" do
          expect(subject).to be_empty
        end
      end

      context "when tag has attributes with correct spacing" do
        let(:source) { '<div class="foo">content</div>' }

        it "does not report an offense" do
          expect(subject).to be_empty
        end
      end

      context "when tag has multiple attributes with correct spacing" do
        let(:source) { '<input class="foo" name="bar">' }

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
    end

    describe "when no space should be present" do
      context "when open tag has extra space before >" do
        let(:source) { "<div   >content</div>" }

        it "reports an offense" do
          expect(subject.size).to eq(1)
          expect(subject.first.message).to eq("Extra space detected where there should be no space.")
        end
      end

      context "when open tag has two spaces before >" do
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
    end

    describe "when space is missing" do
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
    end

    describe "when extra space is present" do
      context "when extra space between tag name and first attribute" do
        let(:source) { '<img   class="hide">' }

        it "reports an offense" do
          expect(subject.size).to eq(1)
          expect(subject.first.message).to eq("Extra space detected where there should be a single space.")
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

      context "when extra space between attributes" do
        let(:source) { "<div class=\"a\"      id=\"b\">content</div>" }

        it "reports an offense" do
          expect(subject.size).to eq(1)
          expect(subject.first.message).to eq("Extra space detected where there should be a single space.")
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
end
