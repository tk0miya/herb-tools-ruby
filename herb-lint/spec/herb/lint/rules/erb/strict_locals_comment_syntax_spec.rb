# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Erb::StrictLocalsCommentSyntax do
  describe ".rule_name" do
    it "returns 'erb-strict-locals-comment-syntax'" do
      expect(described_class.rule_name).to eq("erb-strict-locals-comment-syntax")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Enforce correct syntax for strict_locals magic comment")
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
    let(:context) { build(:context, file_path: "/path/to/_partial.html.erb") }

    context "when comment has valid strict locals syntax" do
      let(:source) { "<%# locals: (name:) %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when comment has valid empty locals" do
      let(:source) { "<%# locals: () %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when comment has valid multiple keyword arguments" do
      let(:source) { "<%# locals: (name:, age: 0, visible: true) %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when comment has valid double-splat argument" do
      let(:source) { "<%# locals: (**attributes) %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when comment is a regular comment (not locals)" do
      let(:source) { "<%# TODO: fix this %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when template has no comments" do
      let(:source) { "<div><%= name %></div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when comment has positional argument (invalid)" do
      let(:source) { "<%# locals: (name) %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-strict-locals-comment-syntax")
        expect(subject.first.message).to include("Positional argument `name` is not allowed")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when comment uses singular local:" do
      let(:source) { "<%# local: (name:) %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Use `locals:` (plural)")
      end
    end

    context "when comment is missing colon (locals())" do
      let(:source) { "<%# locals(name:) %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Use `locals:` with a colon")
      end
    end

    context "when comment is missing space after colon" do
      let(:source) { "<%# locals:(name:) %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Missing space after `locals:`")
      end
    end

    context "when non-comment ERB tag has locals-like content" do
      let(:source) { "<%= locals: (name:) %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when template has both valid locals and other comments" do
      let(:source) do
        <<~ERB
          <%# Regular comment %>
          <%# locals: (name:) %>
          <div><%= name %></div>
        ERB
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when template has invalid locals among other content" do
      let(:source) do
        <<~ERB
          <div>Header</div>
          <%# locals: (name) %>
          <div><%= name %></div>
        ERB
      end

      it "reports exactly one offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-strict-locals-comment-syntax")
      end
    end

    context "when locals declaration uses statement tag with Ruby comment" do
      let(:source) { "<% # locals: (name:) %>" }

      it "reports an offense about using <%# instead" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Use `<%#` instead of `<% #`")
        expect(subject.first.message).to include("Only ERB comment syntax is recognized by Rails")
      end
    end

    context "when locals declaration uses trim statement tag with Ruby comment" do
      let(:source) { "<%- # locals: (name:) %>" }

      it "reports an offense about using <%# instead" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Use `<%#` instead of `<% #`")
      end
    end

    context "when statement tag has a regular Ruby comment (not locals)" do
      let(:source) { "<% # TODO: fix this %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when locals declaration is in a non-partial file" do
      let(:context) { build(:context, file_path: "/path/to/template.html.erb") }
      let(:source) { "<%# locals: (name:) %>" }

      it "reports an offense about non-partial file" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("non-partial file")
        expect(subject.first.message).to include("files starting with `_`")
      end
    end

    context "when invalid locals syntax is in a non-partial file" do
      let(:context) { build(:context, file_path: "/path/to/template.html.erb") }
      let(:source) { "<%# locals: (name) %>" }

      it "reports only the non-partial offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("non-partial file")
      end
    end

    context "when template has duplicate locals declarations" do
      let(:source) do
        <<~ERB
          <%# locals: (name:) %>
          <%# locals: (age:) %>
          <div><%= name %></div>
        ERB
      end

      it "reports an offense for the duplicate" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Duplicate `locals:` declaration")
        expect(subject.first.message).to include("first declaration at line")
      end
    end

    context "when template has three locals declarations" do
      let(:source) do
        <<~ERB
          <%# locals: (name:) %>
          <%# locals: (age:) %>
          <%# locals: (email:) %>
        ERB
      end

      it "reports offenses for each duplicate" do
        expect(subject.size).to eq(2)
        expect(subject).to all(have_attributes(message: include("Duplicate")))
      end
    end
  end
end
