# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Format::Formatter do
  let(:upcase_rewriter_class) do
    Class.new(Herb::Rewriter::StringRewriter) do
      def self.rewriter_name = "upcase-test"
      def self.description = "Upcase for testing"

      def rewrite(formatted, _context)
        formatted.upcase
      end
    end
  end

  let(:pre_rewriters) { [] }
  let(:post_rewriters) { [] }
  let(:config) { build(:formatter_config) }
  let(:formatter) { described_class.new(pre_rewriters, post_rewriters, config) }

  describe "#initialize" do
    it "stores all constructor arguments as attributes" do
      expect(formatter.pre_rewriters).to eq([])
      expect(formatter.post_rewriters).to eq([])
      expect(formatter.config).to eq(config)
    end
  end

  describe "#format" do
    context "with valid source" do
      subject { formatter.format("test.erb", source) }

      # Nested elements trigger indentation, so formatted output differs from input
      let(:source) { "<div><p>Hello</p></div>" }

      it "returns a successful FormatResult with formatting applied" do
        expect(subject).to be_a(Herb::Format::FormatResult)
        expect(subject.file_path).to eq("test.erb")
        expect(subject.original).to eq(source)
        expect(subject.formatted).to eq("<div>\n  <p>Hello</p>\n</div>")
        expect(subject.changed?).to be true
        expect(subject.error?).to be false
        expect(subject.ignored?).to be false
      end
    end

    context "when parse fails" do
      subject { formatter.format("my_file.erb", source) }

      let(:source) { "<div><span></div>" }

      it "returns source unchanged with a ParseError including the file path" do
        expect(subject.formatted).to eq(source)
        expect(subject.error?).to be true
        expect(subject.error).to be_a(Herb::Format::Errors::ParseError)
        expect(subject.error.message).to include("my_file.erb")
      end
    end

    context "when file contains ignore directive" do
      subject { formatter.format("test.erb", source, force: false) }

      let(:source) { "<%# herb:formatter ignore %>\n<div>test</div>" }

      it "returns source unchanged with ignored flag set and no error" do
        expect(subject.formatted).to eq(source)
        expect(subject.ignored?).to be true
        expect(subject.error?).to be false
      end
    end

    context "when force: true and file contains ignore directive" do
      subject { formatter.format("test.erb", source, force: true) }

      let(:source) { "<%# herb:formatter ignore %>\n<div><p>Hello</p></div>" }

      it "formats the file despite directive" do
        expect(subject.ignored?).to be false
        expect(subject.error?).to be false
        expect(subject.changed?).to be true
      end
    end

    context "with pre-rewriters" do
      let(:rewriter) { Herb::Rewriter::BuiltIns::TailwindClassSorter.new }
      let(:formatter_with_rewriter) { described_class.new([rewriter], [], config) }
      let(:source) { '<div class="text-sm flex p-4">hello</div>' }

      it "applies pre-rewriters to the AST before formatting" do
        result = formatter_with_rewriter.format("test.erb", source)

        expect(result.error?).to be false
        expect(result.formatted).to include('class="flex p-4 text-sm"')
      end
    end

    context "with post-rewriters" do
      subject { formatter.format("test.erb", source) }

      let(:post_rewriters) { [upcase_rewriter_class.new] }
      let(:source) { "<div>hello</div>" }

      it "applies post-rewriters to the formatted string" do
        expect(subject.error?).to be false
        expect(subject.formatted).to eq("<DIV>HELLO</DIV>")
      end
    end

    context "with both pre-rewriters and post-rewriters" do
      subject { formatter.format("test.erb", source) }

      let(:pre_rewriters) { [Herb::Rewriter::BuiltIns::TailwindClassSorter.new] }
      let(:post_rewriters) { [upcase_rewriter_class.new] }
      let(:source) { '<div class="text-sm flex">hello</div>' }

      it "applies pre-rewriters to AST then post-rewriters to formatted string" do
        expect(subject.error?).to be false
        expect(subject.formatted).to include('CLASS="FLEX TEXT-SM"')
        expect(subject.formatted).to include("HELLO")
      end
    end

    context "when a post-rewriter raises an error" do
      subject { formatter.format("test.erb", source) }

      let(:broken_rewriter_class) do
        Class.new(Herb::Rewriter::StringRewriter) do
          def self.rewriter_name = "broken-test"
          def self.description = "Broken for testing"

          def rewrite(_formatted, _context)
            raise StandardError, "Post-rewriter error"
          end
        end
      end

      let(:post_rewriters) { [broken_rewriter_class.new] }
      let(:source) { "<div>test</div>" }

      it "returns source unchanged with the raised error" do
        expect(subject.formatted).to eq(source)
        expect(subject.error?).to be true
        expect(subject.error.message).to eq("Post-rewriter error")
      end
    end

    context "when FormatPrinter raises an error" do
      subject { formatter.format("test.erb", source) }

      let(:source) { "<div>test</div>" }

      before do
        allow(Herb::Format::FormatPrinter).to receive(:format).and_raise(StandardError, "Formatting error")
      end

      it "returns source unchanged with the raised error" do
        expect(subject.formatted).to eq(source)
        expect(subject.error?).to be true
        expect(subject.error.message).to eq("Formatting error")
      end
    end
  end
end
