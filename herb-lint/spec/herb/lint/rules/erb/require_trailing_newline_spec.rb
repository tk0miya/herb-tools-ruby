# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Erb::RequireTrailingNewline do
  describe ".rule_name" do
    it "returns 'erb-require-trailing-newline'" do
      expect(described_class.rule_name).to eq("erb-require-trailing-newline")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Require a trailing newline at the end of the file")
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
    let(:context) { build(:context, source:) }

    # Good examples from documentation
    context "when file ends with a single newline (documentation example)" do
      let(:source) { "<%= render partial: \"header\" %>\n<%= render partial: \"footer\" %>\n" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "when file ends with no newline (documentation example)" do
      let(:source) { "<%= render partial: \"header\" %>\n<%= render partial: \"footer\" %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-require-trailing-newline")
        expect(subject.first.message).to eq("File must end with a newline")
        expect(subject.first.severity).to eq("error")
      end
    end

    # Additional edge case tests
    context "when file ends with multiple newlines" do
      let(:source) { "<div>content</div>\n\n" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-require-trailing-newline")
        expect(subject.first.message).to eq("File must end with exactly one newline")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when file is empty" do
      let(:source) { "" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end
  end

  describe "#autofix_source" do
    subject { described_class.new(matcher:).autofix_source(offense, source) }

    let(:matcher) { build(:pattern_matcher) }
    let(:offense) { instance_double(Herb::Lint::Offense) }

    context "when fixing a file with no trailing newline" do
      let(:source) { "<div>content</div>" }
      let(:expected) { "<div>content</div>\n" }

      it "adds a trailing newline" do
        expect(subject).to eq(expected)
      end
    end

    context "when fixing a file with multiple trailing newlines" do
      let(:source) { "<div>content</div>\n\n" }
      let(:expected) { "<div>content</div>\n" }

      it "removes extra newlines" do
        expect(subject).to eq(expected)
      end
    end

    context "when fixing a file with three trailing newlines" do
      let(:source) { "<div>content</div>\n\n\n" }
      let(:expected) { "<div>content</div>\n" }

      it "removes all extra newlines" do
        expect(subject).to eq(expected)
      end
    end

    context "when last node is not a text node and needs newline" do
      let(:source) { "<%= foo %>" }
      let(:expected) { "<%= foo %>\n" }

      it "appends a newline" do
        expect(subject).to eq(expected)
      end
    end

    context "when fixing content with trailing whitespace and no newline" do
      let(:source) { "<div>content</div>  " }
      let(:expected) { "<div>content</div>\n" }

      it "strips trailing whitespace and adds newline" do
        expect(subject).to eq(expected)
      end
    end
  end
end
