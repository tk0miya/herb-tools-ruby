# frozen_string_literal: true

RSpec.describe Herb::Lint::DisableCommentParser do
  describe ".parse_line" do
    context "when the line contains a single-rule disable comment" do
      it "returns a DisableComment with the rule name" do
        result = described_class.parse_line("<%# herb:disable alt-text %>", line_number: 3)
        expect(result).to be_a(Herb::Lint::DisableComment)
        expect(result.rule_names).to eq(["alt-text"])
        expect(result.line).to eq(3)
      end
    end

    context "when the line contains a multi-rule disable comment" do
      it "returns a DisableComment with all rule names" do
        result = described_class.parse_line("<%# herb:disable alt-text, html/lowercase-tags %>", line_number: 1)
        expect(result.rule_names).to eq(["alt-text", "html/lowercase-tags"])
      end
    end

    context "when the line contains a disable-all comment" do
      it "returns a DisableComment with 'all'" do
        result = described_class.parse_line("<%# herb:disable all %>", line_number: 1)
        expect(result.rule_names).to eq(["all"])
        expect(result.disables_all?).to be true
      end
    end

    context "when the line contains extra whitespace" do
      it "handles whitespace around the directive" do
        result = described_class.parse_line("<%#   herb:disable   alt-text   %>", line_number: 1)
        expect(result.rule_names).to eq(["alt-text"])
      end

      it "handles whitespace around comma-separated rules" do
        result = described_class.parse_line("<%# herb:disable  alt-text ,  html/lowercase-tags  %>", line_number: 1)
        expect(result.rule_names).to eq(["alt-text", "html/lowercase-tags"])
      end
    end

    context "when the line does not contain a disable comment" do
      it "returns nil for a regular ERB comment" do
        expect(described_class.parse_line("<%# just a comment %>", line_number: 1)).to be_nil
      end

      it "returns nil for plain HTML" do
        expect(described_class.parse_line("<div>Hello</div>", line_number: 1)).to be_nil
      end

      it "returns nil for an empty line" do
        expect(described_class.parse_line("", line_number: 1)).to be_nil
      end

      it "returns nil for an HTML comment" do
        expect(described_class.parse_line("<!-- herb:disable alt-text -->", line_number: 1)).to be_nil
      end
    end
  end

  describe ".parse" do
    context "with disable comments" do
      let(:source) do
        <<~ERB
          <%# herb:disable alt-text %>
          <img src="decorative.png">
          <%# herb:disable html/lowercase-tags %>
          <DIV>content</DIV>
        ERB
      end

      it "returns a DisableDirectives with collected comments" do
        result = described_class.parse(source)
        expect(result).to be_a(Herb::Lint::DisableDirectives)
        expect(result.comments.size).to eq(2)
        expect(result.comments[0].rule_names).to eq(["alt-text"])
        expect(result.comments[1].rule_names).to eq(["html/lowercase-tags"])
      end

      it "returns ignore_file? as false" do
        result = described_class.parse(source)
        expect(result.ignore_file?).to be false
      end
    end

    context "with a linter ignore directive" do
      let(:source) { "<%# herb:linter ignore %>" }

      it "returns ignore_file? as true" do
        result = described_class.parse(source)
        expect(result.ignore_file?).to be true
      end
    end

    context "with extra whitespace in linter ignore" do
      let(:source) { "<%#   herb:linter   ignore   %>" }

      it "returns ignore_file? as true" do
        result = described_class.parse(source)
        expect(result.ignore_file?).to be true
      end
    end

    context "with no directives" do
      let(:source) { '<img src="test.png" alt="test">' }

      it "returns empty comments and ignore_file? false" do
        result = described_class.parse(source)
        expect(result.comments).to be_empty
        expect(result.ignore_file?).to be false
      end
    end

    context "with both disable and ignore directives" do
      let(:source) do
        <<~ERB
          <%# herb:linter ignore %>
          <%# herb:disable alt-text %>
          <img src="test.png">
        ERB
      end

      it "collects both ignore flag and disable comments" do
        result = described_class.parse(source)
        expect(result.ignore_file?).to be true
        expect(result.comments.size).to eq(1)
        expect(result.comments[0].rule_names).to eq(["alt-text"])
      end
    end
  end
end
