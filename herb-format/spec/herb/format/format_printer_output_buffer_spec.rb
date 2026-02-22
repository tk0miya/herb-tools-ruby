# frozen_string_literal: true

RSpec.describe Herb::Format::FormatPrinter do
  let(:indent_width) { 2 }
  let(:max_line_length) { 80 }
  let(:source) { "" }
  let(:format_context) { build(:context, source:, indent_width:, max_line_length:) }

  describe "#push" do
    let(:printer) do
      Class.new(described_class) do
        public :push
        attr_reader :string_line_count
      end.new(indent_width:, max_line_length:, format_context:)
    end

    it "appends a line to the capture buffer" do
      result = printer.capture { printer.push("hello") }

      expect(result).to eq(["hello"])
    end

    it "increments string_line_count by 1 when line contains one newline" do
      printer.push("line\n")

      expect(printer.string_line_count).to eq(1)
    end

    it "increments string_line_count by the number of newlines in the string" do
      printer.push("\n\n\n")

      expect(printer.string_line_count).to eq(3)
    end

    it "does not increment string_line_count for lines without newlines" do
      printer.push("no newline")

      expect(printer.string_line_count).to eq(0)
    end
  end

  describe "#indent" do
    subject { printer.send(:indent) }

    let(:printer) do
      Class.new(described_class) do
        public :indent
        attr_accessor :indent_level
      end.new(indent_width:, max_line_length:, format_context:)
    end

    context "with indent_level 0" do
      it { is_expected.to eq("") }
    end

    context "with indent_level 1" do
      before { printer.indent_level = 1 }

      it { is_expected.to eq("  ") }
    end

    context "with indent_level 2" do
      before { printer.indent_level = 2 }

      it { is_expected.to eq("    ") }
    end

    context "with custom indent_width" do
      let(:indent_width) { 4 }

      before { printer.indent_level = 1 }

      it { is_expected.to eq("    ") }
    end
  end

  describe "#push_with_indent" do
    let(:printer) do
      Class.new(described_class) do
        public :push_with_indent
        attr_accessor :indent_level
      end.new(indent_width:, max_line_length:, format_context:)
    end

    context "with indent_level 0" do
      it "pushes the line without indentation" do
        result = printer.capture { printer.push_with_indent("hello") }

        expect(result).to eq(["hello"])
      end
    end

    context "with indent_level 1" do
      before { printer.indent_level = 1 }

      it "pushes the line with indentation" do
        result = printer.capture { printer.push_with_indent("hello") }

        expect(result).to eq(["  hello"])
      end
    end

    context "with empty line" do
      before { printer.indent_level = 2 }

      it "pushes empty line without indentation" do
        result = printer.capture { printer.push_with_indent("") }

        expect(result).to eq([""])
      end
    end

    context "with whitespace-only line" do
      before { printer.indent_level = 1 }

      it "pushes whitespace-only line without indentation" do
        result = printer.capture { printer.push_with_indent("   ") }

        expect(result).to eq(["   "])
      end
    end
  end

  describe "#push_to_last_line" do
    let(:printer) do
      Class.new(described_class) do
        public :push, :push_to_last_line
      end.new(indent_width:, max_line_length:, format_context:)
    end

    context "when buffer is empty" do
      it "starts a new line with the text" do
        result = printer.capture { printer.push_to_last_line("hello") }

        expect(result).to eq(["hello"])
      end
    end

    context "when buffer has lines" do
      it "appends text to the last line without adding a new element" do
        result = printer.capture do
          printer.push("first")
          printer.push_to_last_line(" appended")
        end

        expect(result).to eq(["first appended"])
      end

      it "appends to the last of multiple lines" do
        result = printer.capture do
          printer.push("line1")
          printer.push("line2")
          printer.push_to_last_line(" suffix")
        end

        expect(result).to eq(["line1", "line2 suffix"])
      end
    end
  end

  describe "#with_indent" do
    let(:printer) do
      Class.new(described_class) do
        public :with_indent
        attr_reader :indent_level
      end.new(indent_width:, max_line_length:, format_context:)
    end

    it "increases indent_level by 1 inside the block" do
      printer.with_indent do
        expect(printer.indent_level).to eq(1)
      end
    end

    it "restores indent_level to 0 after the block" do
      printer.with_indent { nil }

      expect(printer.indent_level).to eq(0)
    end

    it "supports nested with_indent calls" do
      printer.with_indent do
        printer.with_indent do
          expect(printer.indent_level).to eq(2)
        end
        expect(printer.indent_level).to eq(1)
      end
      expect(printer.indent_level).to eq(0)
    end
  end

  describe "#capture" do
    subject { printer.capture { nil } }

    let(:printer) do
      Class.new(described_class) do
        public :push
        attr_reader :string_line_count
        attr_accessor :inline_mode
      end.new(indent_width:, max_line_length:, format_context:)
    end

    it "returns an empty array when block produces no output" do
      expect(subject).to eq([])
    end

    context "with lines pushed inside block" do
      subject { printer.capture { printer.push("hello") } }

      it "captures the pushed lines" do
        expect(subject).to eq(["hello"])
      end
    end

    context "with lines pushed before and inside capture" do
      it "isolates captured output from outer buffer" do
        printer.push("outer")
        result = printer.capture { printer.push("inner") }

        expect(result).to eq(["inner"])
      end

      it "restores the outer buffer after capture" do
        printer.push("outer")
        printer.capture { printer.push("inner") }
        result = printer.capture { printer.push("check") }

        expect(result).to eq(["check"])
      end
    end

    context "with string_line_count incremented inside block" do
      it "restores string_line_count after capture" do
        printer.push("outer\n")
        printer.capture { printer.push("inner\n") }

        expect(printer.string_line_count).to eq(1)
      end
    end

    context "with inline_mode set to true" do
      before { printer.inline_mode = true }

      it "restores inline_mode after capture" do
        printer.capture { nil }

        expect(printer.inline_mode).to be true
      end
    end
  end
end
