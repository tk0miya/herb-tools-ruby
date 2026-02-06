# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::ErbStrictLocalsCommentSyntax do
  describe ".rule_name" do
    it "returns 'erb-strict-locals-comment-syntax'" do
      expect(described_class.rule_name).to eq("erb-strict-locals-comment-syntax")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Enforce correct syntax for strict locals magic comments")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    subject { described_class.new.check(document, context) }

    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context, file_path:) }
    let(:file_path) { "_partial.html.erb" }

    context "when using valid strict locals comments" do
      let(:source) { "<%# locals: (user:, admin: false) %>\n<p><%= user.name %></p>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with single parameter" do
      let(:source) { "<%# locals: (title:) %>\n<h1><%= title %></h1>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with empty locals" do
      let(:source) { "<%# locals: () %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with complex default values" do
      let(:source) { "<%# locals: (items: [], config: {}) %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with string default values" do
      let(:source) { '<%# locals: (name: "default", count: 0) %>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with lambda default values" do
      let(:source) { "<%# locals: (callback: -> { nil }) %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with double-splat for optional keyword arguments" do
      let(:source) { '<%# locals: (message: "Hello", **attributes) %>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with only double-splat" do
      let(:source) { "<%# locals: (**options) %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ignoring non-locals comments" do
      let(:source) { "<%# just a regular comment %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ignoring regular Ruby comments in execution tags" do
      let(:source) { "<% # this is just a regular comment %>\n<% # nothing to see here %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when using locals() without colon" do
      let(:source) { "<%# locals() %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-strict-locals-comment-syntax")
        expect(subject.first.message).to eq(
          "Use `locals:` with a colon, not `locals()`. Correct format: `<%# locals: (...) %>`."
        )
      end
    end

    context "when using local: (singular) instead of locals:" do
      let(:source) { "<%# local: (user:) %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Use `locals:` (plural), not `local:`.")
      end
    end

    context "when missing colon before parentheses" do
      let(:source) { "<%# locals (user:) %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Use `locals:` with a colon before the parentheses, not `locals (`.")
      end
    end

    context "when missing space after colon (empty)" do
      let(:source) { "<%# locals:() %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "Missing space after `locals:`. Rails Strict Locals require a space after the colon: " \
          "`<%# locals: (...) %>`."
        )
      end
    end

    context "when missing space after colon (with locals)" do
      let(:source) { "<%# locals:(title:) %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "Missing space after `locals:`. Rails Strict Locals require a space after the colon: " \
          "`<%# locals: (...) %>`."
        )
      end
    end

    context "when missing parentheses around parameters" do
      let(:source) { "<%# locals: user %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "Wrap parameters in parentheses: `locals: (name:)` or `locals: (name: default)`."
        )
      end
    end

    context "when empty locals: without parentheses" do
      let(:source) { "<%# locals: %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "Add parameters after `locals:`. Use `locals: (name:)` or `locals: ()` for no locals."
        )
      end
    end

    context "when parentheses are unbalanced" do
      let(:source) { "<%# locals: (user: %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "Unbalanced parentheses in `locals:` comment. " \
          "Ensure all opening parentheses have matching closing parentheses."
        )
      end
    end

    context "when using Ruby comment syntax in execution tags" do
      let(:source) { "<% # locals: (user:) %>\n<%- # locals: (admin: false) %>" }

      it "reports offenses for both" do
        expect(subject.size).to eq(2)
        expect(subject[0].message).to eq(
          "Use `<%#` instead of `<% #` for strict locals comments. " \
          "Only ERB comment syntax is recognized by Rails."
        )
        expect(subject[1].message).to eq(
          "Use `<%#` instead of `<%- #` for strict locals comments. " \
          "Only ERB comment syntax is recognized by Rails."
        )
      end
    end

    context "when using positional arguments" do
      let(:source) { "<%# locals: (user) %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "Positional argument `user` is not allowed. Use keyword argument format: `user:`."
        )
      end
    end

    context "when using block arguments" do
      let(:source) { "<%# locals: (&block) %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "Block argument `&block` is not allowed. Strict locals only support keyword arguments."
        )
      end
    end

    context "when using single splat arguments" do
      let(:source) { "<%# locals: (*args) %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "Splat argument `*args` is not allowed. Strict locals only support keyword arguments."
        )
      end
    end

    context "when using trailing comma" do
      let(:source) { "<%# locals: (user:,) %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Unexpected comma in `locals:` parameters.")
      end
    end

    context "when using leading comma" do
      let(:source) { "<%# locals: (, user:) %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Unexpected comma in `locals:` parameters.")
      end
    end

    context "when using double commas" do
      let(:source) { "<%# locals: (user:,, admin:) %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Unexpected comma in `locals:` parameters.")
      end
    end

    context "when duplicate strict locals comments exist" do
      let(:source) { "<%# locals: (user:) %>\n<p>Content</p>\n<%# locals: (admin:) %>" }

      it "reports an offense for duplicate" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to match(/Duplicate `locals:` declaration/)
        expect(subject.first.message).to match(/first declaration at line 1/)
      end
    end

    context "when strict locals comment is not at the top" do
      let(:source) { "<p>Some content before</p>\n<%# locals: (user:) %>\n<p>Content after</p>" }

      it "does not report an offense (allowed anywhere in partial)" do
        expect(subject).to be_empty
      end
    end

    context "with partial file names" do
      let(:source) { "<%# locals: (user:) %>" }

      it "does not report an offense for files starting with underscore" do
        context_with_path = build(:context, file_path: "app/views/users/_user.html.erb")
        result = described_class.new.check(document, context_with_path)
        expect(result).to be_empty
      end
    end

    context "with non-partial file names" do
      let(:source) { "<%# locals: (user:) %>" }
      let(:file_path) { "app/views/users/show.html.erb" }

      it "reports a warning when used in non-partial files" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "Strict locals (`locals:`) only work in partials (files starting with `_`). " \
          "This declaration will be ignored."
        )
      end
    end

    context "when filename is not provided (unknown context)" do
      let(:source) { "<%# locals: (user:) %>" }
      let(:file_path) { nil }

      it "does not report a warning about non-partial" do
        expect(subject).to be_empty
      end
    end
  end
end
