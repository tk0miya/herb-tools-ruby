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

  describe ".parse_source" do
    context "with a single disable comment" do
      let(:source) do
        <<~ERB
          <%# herb:disable alt-text %>
          <img src="decorative.png">
        ERB
      end

      it "maps the target line (next line) to the DisableComment" do
        cache = described_class.parse_source(source)
        expect(cache.size).to eq(1)
        expect(cache[2]).to be_a(Herb::Lint::DisableComment)
        expect(cache[2].rule_names).to eq(["alt-text"])
      end
    end

    context "with multiple disable comments" do
      let(:source) do
        <<~ERB
          <%# herb:disable alt-text %>
          <img src="decorative.png">
          <%# herb:disable html/lowercase-tags %>
          <DIV>content</DIV>
        ERB
      end

      it "maps each target line to its DisableComment" do
        cache = described_class.parse_source(source)
        expect(cache.size).to eq(2)
        expect(cache[2].rule_names).to eq(["alt-text"])
        expect(cache[4].rule_names).to eq(["html/lowercase-tags"])
      end
    end

    context "with a disable-all comment" do
      let(:source) do
        <<~ERB
          <%# herb:disable all %>
          <IMG src="test.png">
        ERB
      end

      it "maps the target line with disables_all? true" do
        cache = described_class.parse_source(source)
        expect(cache[2].disables_all?).to be true
      end
    end

    context "with no disable comments" do
      let(:source) do
        <<~ERB
          <img src="test.png" alt="test">
          <div>content</div>
        ERB
      end

      it "returns an empty cache" do
        cache = described_class.parse_source(source)
        expect(cache).to be_empty
      end
    end

    context "with a disable comment on the last line" do
      let(:source) { "<%# herb:disable alt-text %>" }

      it "maps to the line after the source" do
        cache = described_class.parse_source(source)
        expect(cache[2]).to be_a(Herb::Lint::DisableComment)
      end
    end
  end
end
