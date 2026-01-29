# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Erb::NoTrailingWhitespace do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template) }
  let(:context) { instance_double(Herb::Lint::Context, source: template) }

  describe ".rule_name" do
    it "returns 'erb/erb-no-trailing-whitespace'" do
      expect(described_class.rule_name).to eq("erb/erb-no-trailing-whitespace")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("No trailing whitespace in ERB output")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    context "when ERB output tag has no trailing whitespace" do
      let(:template) { "<%= @user.name %>\n" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when there is trailing whitespace after ERB output tag" do
      let(:template) { "<%= @user.name %>  \n" }

      it "reports an offense at the tag closing position" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb/erb-no-trailing-whitespace")
        expect(subject.first.message).to eq("Trailing whitespace detected")
        expect(subject.first.severity).to eq("warning")
        expect(subject.first.line).to eq(1)
        expect(subject.first.column).to eq(17)
      end
    end

    context "when there is trailing whitespace after ERB control tag" do
      let(:template) { "<% if @show %>  \n<% end %>\n" }

      it "reports an offense for the control tag line" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(1)
        expect(subject.first.column).to eq(14)
      end
    end

    context "when there is trailing tab after ERB tag" do
      let(:template) { "<%= @name %>\t\n" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(1)
        expect(subject.first.column).to eq(12)
      end
    end

    context "when there is mixed trailing whitespace after ERB tag" do
      let(:template) { "<%= @name %> \t  \n" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(1)
        expect(subject.first.column).to eq(12)
      end
    end

    context "when multiple ERB tags on different lines have trailing whitespace" do
      let(:template) { "<%= @a %>  \n<%= @b %>  \n" }

      it "reports an offense for each line" do
        expect(subject.size).to eq(2)
        expect(subject[0].line).to eq(1)
        expect(subject[1].line).to eq(2)
      end
    end

    context "when ERB end tag has trailing whitespace" do
      let(:template) { "<% if true %>\n<% end %>  \n" }

      it "reports an offense for the end tag line" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
        expect(subject.first.column).to eq(9)
      end
    end

    context "when ERB comment tag has trailing whitespace" do
      let(:template) { "<%# comment %>  \n" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(1)
        expect(subject.first.column).to eq(14)
      end
    end

    context "when ERB tag is followed by non-whitespace content" do
      let(:template) { "<%= @name %> text\n" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when plain HTML has trailing whitespace but no ERB tags" do
      let(:template) { "<div>text</div>  \n" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB tag is at end of file without trailing whitespace" do
      let(:template) { "<%= @name %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB tag uses trim closing (-%>)" do
      let(:template) { "<%= @name -%>  \n" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(1)
        expect(subject.first.column).to eq(13)
      end
    end
  end
end
