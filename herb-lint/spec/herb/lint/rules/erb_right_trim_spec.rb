# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::ErbRightTrim do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template, track_whitespace: true) }
  let(:context) { build(:context) }

  describe ".rule_name" do
    it "returns 'erb-right-trim'" do
      expect(described_class.rule_name).to eq("erb-right-trim")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Use `-%>` instead of `=%>` for right-trimming")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    context "when ERB tag uses obscure =%> syntax" do
      let(:template) do
        <<~ERB
          <% if condition =%>
            <p>Content</p>
          <% end =%>
        ERB
      end

      it "reports offenses for both tags" do
        expect(subject.size).to eq(2)
        expect(subject.first.rule_name).to eq("erb-right-trim")
        expect(subject.first.message).to eq(
          "Use `-%>` instead of `=%>` for right-trimming. " \
          "The `=%>` syntax is obscure and not well-supported in most ERB engines."
        )
      end
    end

    context "when ERB tag uses standard %> syntax" do
      let(:template) do
        <<~ERB
          <% if condition %>
            <p>Content</p>
          <% end %>
        ERB
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB tag uses standard -%> syntax" do
      let(:template) do
        <<~ERB
          <% if condition -%>
            <p>Content</p>
          <% end -%>
        ERB
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB output tag uses =%> syntax" do
      let(:template) { "<%= value =%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Use `-%>` instead of `=%>`")
      end
    end

    context "when mixing =%> with other syntaxes" do
      let(:template) do
        <<~ERB
          <% if condition =%>
            <%= value %>
          <% end -%>
        ERB
      end

      it "reports offense only for =%> tag" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Use `-%>` instead of `=%>`")
      end
    end

    context "when no ERB tags exist" do
      let(:template) { "<div>Plain HTML</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB comment uses =%> syntax" do
      let(:template) { "<%# comment =%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Use `-%>` instead of `=%>`")
      end
    end
  end
end
