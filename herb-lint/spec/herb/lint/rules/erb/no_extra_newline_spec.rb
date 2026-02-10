# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Erb::NoExtraNewline do
  describe ".rule_name" do
    it "returns 'erb-no-extra-newline'" do
      expect(described_class.rule_name).to eq("erb-no-extra-newline")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow more than 2 consecutive blank lines in ERB files")
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
    let(:context) { build(:context, source:) }

    # Good examples from documentation
    context "with one blank line between content" do
      let(:source) { "line 1\n\nline 3" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with two blank lines between sections" do
      let(:source) do
        <<~ERB
          <div>
           <h1>Section 1</h1>


           <h1>Section 2</h1>
          </div>
        ERB
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "with three blank lines between content" do
      let(:source) { "line 1\n\n\n\nline 3" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-newline")
      end
    end

    context "with three blank lines inside div" do
      let(:source) do
        <<~ERB
          <div>
           <h1>Title</h1>



           <p>Content</p>
          </div>
        ERB
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-newline")
      end
    end

    context "with four blank lines between ERB output tags" do
      let(:source) { "<%= user.name %>\n\n\n\n\n<%= user.email %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-newline")
      end
    end

    context "when there are no blank lines" do
      let(:source) { "<div>First</div>\n<div>Second</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when there are 5 blank lines (6 newlines)" do
      let(:source) { "<div>First</div>\n\n\n\n\n\n<div>Second</div>" }

      it "reports an offense for 3 extra lines" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-newline")
        expect(subject.first.message).to eq(
          "Extra blank line detected. Remove 3 blank lines to maintain consistent spacing (max 2 allowed)"
        )
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when there are multiple violations" do
      let(:source) do
        "<div>First</div>\n\n\n\n<div>Second</div>\n\n\n\n\n<div>Third</div>"
      end

      it "reports multiple offenses" do
        expect(subject.size).to eq(2)
        expect(subject[0].message).to eq(
          "Extra blank line detected. Remove 1 blank line to maintain consistent spacing (max 2 allowed)"
        )
        expect(subject[1].message).to eq(
          "Extra blank line detected. Remove 2 blank lines to maintain consistent spacing (max 2 allowed)"
        )
      end
    end

    context "when excess newlines are inside ERB tags" do
      let(:source) { "<%\n\n\n\nvalue\n%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-newline")
      end
    end

    context "when excess newlines are between ERB tags and HTML" do
      let(:source) { "<% if true %>\n\n\n\n<div>content</div>\n<% end %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-newline")
      end
    end

    context "when file is empty" do
      let(:source) { "" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when file contains only newlines" do
      let(:source) { "\n\n\n\n\n" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end
  end
end
