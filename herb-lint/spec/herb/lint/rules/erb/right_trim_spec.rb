# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Erb::RightTrim do
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
    subject { described_class.new.check(document, context) }

    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    context "when ERB tag uses obscure =%> syntax" do
      let(:source) do
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
      let(:source) do
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
      let(:source) do
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
      let(:source) { "<%= value =%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Use `-%>` instead of `=%>`")
      end
    end

    context "when mixing =%> with other syntaxes" do
      let(:source) do
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
      let(:source) { "<div>Plain HTML</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB comment uses =%> syntax" do
      let(:source) { "<%# comment =%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Use `-%>` instead of `=%>`")
      end
    end
  end

  describe ".safe_autofixable?" do
    it "returns true" do
      expect(described_class.safe_autofixable?).to be(true)
    end
  end

  describe "#autofix" do
    subject { described_class.new.autofix(node, document) }

    let(:document) { Herb.parse(source, track_whitespace: true) }

    context "when fixing an ERB output tag" do
      let(:source) { "<%= value =%>" }
      let(:expected) { "<%= value -%>" }
      let(:node) { document.value.children.first }

      it "replaces =%> with -%> and returns true" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing an ERB statement tag" do
      let(:source) { "<% foo =%>" }
      let(:expected) { "<% foo -%>" }
      let(:node) { document.value.children.first }

      it "replaces =%> with -%>" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing an ERB comment tag" do
      let(:source) { "<%# comment =%>" }
      let(:expected) { "<%# comment -%>" }
      let(:node) { document.value.children.first }

      it "replaces =%> with -%>" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing an ERB if node" do
      let(:source) do
        <<~ERB.chomp
          <% if condition =%>
            <p>Content</p>
          <% end %>
        ERB
      end
      let(:expected) do
        <<~ERB.chomp
          <% if condition -%>
            <p>Content</p>
          <% end %>
        ERB
      end
      let(:node) { document.value.children.first }

      it "replaces =%> with -%> on the if tag" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing an ERB end node" do
      let(:source) do
        <<~ERB.chomp
          <% if condition %>
            <p>Content</p>
          <% end =%>
        ERB
      end
      let(:expected) do
        <<~ERB.chomp
          <% if condition %>
            <p>Content</p>
          <% end -%>
        ERB
      end
      let(:node) do
        document.value.children.first.end_node
      end

      it "replaces =%> with -%> on the end tag via parent" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end
  end
end
