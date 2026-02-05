# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::ErbCommentSyntax do
  describe ".rule_name" do
    it "returns 'erb-comment-syntax'" do
      expect(described_class.rule_name).to eq("erb-comment-syntax")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Enforce ERB comment style")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    subject { described_class.new.check(document, context) }

    let(:document) { Herb.parse(template, track_whitespace: true) }
    let(:context) { build(:context) }

    context "when using proper ERB comment syntax" do
      let(:template) { "<%# This is a comment %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when using statement tag with Ruby line comment" do
      let(:template) { "<% # This is a comment %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-comment-syntax")
        expect(subject.first.message).to eq("Use ERB comment tag `<%#` instead of `<% #`")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when ERB tag contains code, not a comment" do
      let(:template) { "<% foo %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB output tag is used" do
      let(:template) { "<%= output %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiple bad comments exist" do
      let(:template) do
        <<~ERB
          <% # first comment %>
          <p>content</p>
          <% # second comment %>
        ERB
      end

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
      end
    end

    context "when both good and bad comments exist" do
      let(:template) do
        <<~ERB
          <%# good comment %>
          <% # bad comment %>
        ERB
      end

      it "reports only one offense for the bad comment" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end

    context "when statement tag has multiple spaces before hash" do
      let(:template) { "<%   # comment %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-comment-syntax")
      end
    end

    context "when code contains a hash character in non-comment context" do
      let(:template) { "<% foo(a: 1) # inline comment %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end
  end
end
