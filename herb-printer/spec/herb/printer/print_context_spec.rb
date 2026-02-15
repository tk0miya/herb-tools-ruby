# frozen_string_literal: true

RSpec.describe Herb::Printer::PrintContext do
  let(:context) { described_class.new }

  describe "#write" do
    it "appends text to the output buffer" do
      context.write("hello")
      context.write(" world")

      expect(context.output).to eq("hello world")
    end
  end

  describe "#output" do
    subject { context.output }

    context "when text has been written" do
      before do
        context.write("first")
        context.write(" second")
      end

      it { is_expected.to eq("first second") }
    end

    context "when nothing has been written" do
      it { is_expected.to eq("") }
    end
  end

  describe "#reset" do
    it "clears all state" do
      context.write("some text")
      context.indent
      context.indent
      context.write_with_column_tracking("col tracking")
      context.enter_tag("div")

      context.reset

      expect(context).to have_attributes(
        output: "",
        current_indent_level: 0,
        current_column: 0,
        tag_stack: be_empty
      )
    end
  end

  describe "#indent / #dedent" do
    it "tracks indent level" do
      expect(context.current_indent_level).to eq(0)

      context.indent
      expect(context.current_indent_level).to eq(1)

      context.indent
      expect(context.current_indent_level).to eq(2)

      context.dedent
      expect(context.current_indent_level).to eq(1)

      context.dedent
      expect(context.current_indent_level).to eq(0)
    end

    context "with block" do
      it "automatically calls dedent after block completes" do
        context.indent do
          expect(context.current_indent_level).to eq(1)
        end

        expect(context.current_indent_level).to eq(0)
      end

      it "supports nested blocks" do
        context.indent do
          expect(context.current_indent_level).to eq(1)

          context.indent do
            expect(context.current_indent_level).to eq(2)
          end

          expect(context.current_indent_level).to eq(1)
        end

        expect(context.current_indent_level).to eq(0)
      end

      it "calls dedent even if block raises an exception" do
        expect do
          context.indent do
            raise "error"
          end
        end.to raise_error("error")

        expect(context.current_indent_level).to eq(0)
      end

      it "can be used with manual indent/dedent calls" do
        context.indent

        context.indent do
          expect(context.current_indent_level).to eq(2)
        end

        expect(context.current_indent_level).to eq(1)

        context.dedent
        expect(context.current_indent_level).to eq(0)
      end
    end
  end

  describe "#write_with_column_tracking" do
    context "with text without newlines" do
      before { context.write_with_column_tracking("hello") }

      it "tracks column position" do
        expect(context.current_column).to eq(5)
      end
    end

    context "with text containing a newline" do
      before { context.write_with_column_tracking("hello\nworld") }

      it "resets column after the newline" do
        expect(context.current_column).to eq(5)
      end
    end

    context "with multiple writes" do
      before do
        context.write_with_column_tracking("abc")
        context.write_with_column_tracking("de")
      end

      it "tracks column across writes" do
        expect(context.current_column).to eq(5)
      end
    end

    context "with multiple newlines" do
      before { context.write_with_column_tracking("line1\nline2\nend") }

      it "tracks column from the last newline" do
        expect(context.current_column).to eq(3)
      end
    end

    context "when text ends with a newline" do
      before { context.write_with_column_tracking("hello\n") }

      it "sets column to 0" do
        expect(context.current_column).to eq(0)
      end
    end

    it "appends text to the output buffer" do
      context.write_with_column_tracking("hello")
      context.write_with_column_tracking(" world")

      expect(context.output).to eq("hello world")
    end
  end

  describe "#enter_tag / #exit_tag" do
    it "maintains the tag stack" do
      context.enter_tag("div")
      expect(context.tag_stack).to eq(["div"])

      context.enter_tag("span")
      expect(context.tag_stack).to eq(%w[div span])

      context.exit_tag
      expect(context.tag_stack).to eq(["div"])

      context.exit_tag
      expect(context.tag_stack).to be_empty
    end

    it "returns a copy of the tag stack" do
      context.enter_tag("div")
      stack = context.tag_stack
      stack.push("modified")

      expect(context.tag_stack).to eq(["div"])
    end

    context "with block" do
      it "automatically calls exit_tag after block completes" do
        context.enter_tag("div") do
          expect(context.tag_stack).to eq(["div"])
        end

        expect(context.tag_stack).to be_empty
      end

      it "supports nested blocks" do
        context.enter_tag("div") do
          expect(context.tag_stack).to eq(["div"])

          context.enter_tag("span") do
            expect(context.tag_stack).to eq(%w[div span])
          end

          expect(context.tag_stack).to eq(["div"])
        end

        expect(context.tag_stack).to be_empty
      end

      it "calls exit_tag even if block raises an exception" do
        expect do
          context.enter_tag("div") do
            raise "error"
          end
        end.to raise_error("error")

        expect(context.tag_stack).to be_empty
      end

      it "can be used with manual enter_tag/exit_tag calls" do
        context.enter_tag("div")

        context.enter_tag("span") do
          expect(context.tag_stack).to eq(%w[div span])
        end

        expect(context.tag_stack).to eq(["div"])

        context.exit_tag
        expect(context.tag_stack).to be_empty
      end
    end
  end

  describe "#at_start_of_line?" do
    subject { context.at_start_of_line? }

    context "when at initial state" do
      it { is_expected.to be true }
    end

    context "when text has been written" do
      before { context.write_with_column_tracking("text") }

      it { is_expected.to be false }
    end

    context "when text ending with a newline has been written" do
      before { context.write_with_column_tracking("text\n") }

      it { is_expected.to be true }
    end
  end
end
