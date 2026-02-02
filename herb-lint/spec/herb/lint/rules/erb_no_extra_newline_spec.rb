# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::ErbNoExtraNewline do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template, track_whitespace: true) }
  let(:context) { build(:context) }

  describe ".rule_name" do
    it "returns 'erb-no-extra-newline'" do
      expect(described_class.rule_name).to eq("erb-no-extra-newline")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow extra blank lines inside ERB tags")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    context "when ERB tag has single-line content" do
      let(:template) { "<% value %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB tag has multi-line content without extra blank lines" do
      let(:template) do
        <<~ERB
          <% if condition
               do_something
             end %>
        ERB
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB tag has content with single newline at start" do
      let(:template) do
        <<~ERB
          <%
            value
          %>
        ERB
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB tag has leading blank line" do
      let(:template) do
        <<~ERB
          <%

            value
          %>
        ERB
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-newline")
        expect(subject.first.message).to eq("Remove extra blank lines inside ERB tag")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when ERB tag has trailing blank line" do
      let(:template) do
        <<~ERB
          <%
            value

          %>
        ERB
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-newline")
        expect(subject.first.message).to eq("Remove extra blank lines inside ERB tag")
      end
    end

    context "when ERB tag has both leading and trailing blank lines" do
      let(:template) do
        <<~ERB
          <%

            value

          %>
        ERB
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-newline")
      end
    end

    context "when ERB tag has multiple consecutive blank lines in the middle" do
      let(:template) do
        <<~ERB
          <% first_line


            second_line %>
        ERB
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-newline")
      end
    end

    context "when ERB output tag has extra blank lines" do
      let(:template) do
        <<~ERB
          <%=

            value
          %>
        ERB
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-newline")
      end
    end

    context "when multiple ERB tags have extra blank lines" do
      let(:template) do
        <<~ERB
          <%

            first
          %>
          <p>content</p>
          <%=

            second
          %>
        ERB
      end

      it "reports an offense for each tag with extra blank lines" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:line)).to contain_exactly(1, 6)
      end
    end

    context "when ERB tag has blank lines with spaces" do
      let(:template) do
        "<%\n  \n  value\n%>"
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-newline")
      end
    end

    context "when ERB tag has blank lines with tabs" do
      let(:template) do
        "<%\n\t\n\tvalue\n%>"
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-newline")
      end
    end

    context "when ERB tag is empty" do
      let(:template) { "<% %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB tag has only newlines" do
      let(:template) { "<%\n\n%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-newline")
      end
    end

    context "when content has single newline separating statements" do
      let(:template) do
        <<~ERB
          <% first
          second %>
        ERB
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end
  end
end
