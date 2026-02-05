# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::ErbNoExtraNewline do
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
    subject { described_class.new.check(document, context) }

    let(:document) { Herb.parse(template, track_whitespace: true) }
    let(:context) { build(:context, source: template) }

    context "when there are no blank lines" do
      let(:template) { "<div>First</div>\n<div>Second</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when there is 1 blank line (2 newlines)" do
      let(:template) { "<div>First</div>\n\n<div>Second</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when there are 2 blank lines (3 newlines)" do
      let(:template) { "<div>First</div>\n\n\n<div>Second</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when there are 3 blank lines (4 newlines)" do
      let(:template) { "<div>First</div>\n\n\n\n<div>Second</div>" }

      it "reports an offense for 1 extra line" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-newline")
        expect(subject.first.message).to eq(
          "Extra blank line detected. Remove 1 blank line to maintain consistent spacing (max 2 allowed)"
        )
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when there are 4 blank lines (5 newlines)" do
      let(:template) { "<div>First</div>\n\n\n\n\n<div>Second</div>" }

      it "reports an offense for 2 extra lines" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-newline")
        expect(subject.first.message).to eq(
          "Extra blank line detected. Remove 2 blank lines to maintain consistent spacing (max 2 allowed)"
        )
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when there are 5 blank lines (6 newlines)" do
      let(:template) { "<div>First</div>\n\n\n\n\n\n<div>Second</div>" }

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
      let(:template) do
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
      let(:template) { "<%\n\n\n\nvalue\n%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-newline")
      end
    end

    context "when excess newlines are between ERB tags and HTML" do
      let(:template) { "<% if true %>\n\n\n\n<div>content</div>\n<% end %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-newline")
      end
    end

    context "when file is empty" do
      let(:template) { "" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when file contains only newlines" do
      let(:template) { "\n\n\n\n\n" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end
  end
end
