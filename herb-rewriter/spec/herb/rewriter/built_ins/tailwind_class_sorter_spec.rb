# frozen_string_literal: true

require "spec_helper"
require "herb/printer"

RSpec.describe Herb::Rewriter::BuiltIns::TailwindClassSorter do
  let(:rewriter) { described_class.new }
  let(:context) { nil }

  describe ".rewriter_name" do
    subject { described_class.rewriter_name }

    it { is_expected.to eq("tailwind-class-sorter") }
  end

  describe ".description" do
    subject { described_class.description }

    it "returns a non-empty string" do
      expect(subject).to be_a(String)
      expect(subject).not_to be_empty
    end
  end

  describe "#initialize" do
    context "with options" do
      it "stores the options" do
        rewriter = described_class.new(options: { enabled: true })
        expect(rewriter.options).to eq({ enabled: true })
      end
    end

    context "without options" do
      it "defaults to empty hash" do
        expect(rewriter.options).to eq({})
      end
    end
  end

  describe "#rewrite" do
    subject { rewriter.rewrite(ast, context) }

    let(:ast) { Herb.parse(source, track_whitespace: true).value }

    context "with unsorted class attribute" do
      let(:source) { '<div class="px-4 bg-blue-500 text-white">Hello</div>' }

      it "sorts classes in recommended order" do
        # px-4 (spacing=4) < text-white (typography=5) < bg-blue-500 (backgrounds=6)
        expect(Herb::Printer::IdentityPrinter.print(subject)).to eq(
          '<div class="px-4 text-white bg-blue-500">Hello</div>'
        )
      end
    end

    context "with already sorted classes" do
      let(:source) { '<div class="px-4 bg-blue-500">Hello</div>' }

      it "leaves the output unchanged" do
        expect(Herb::Printer::IdentityPrinter.print(subject)).to eq(source)
      end
    end

    context "with no class attributes" do
      let(:source) { "<div><p>Hello</p></div>" }

      it "leaves the output unchanged" do
        expect(Herb::Printer::IdentityPrinter.print(subject)).to eq(source)
      end
    end

    context "with multiple class attributes" do
      let(:source) do
        '<div class="bg-red-500 px-4"><span class="rounded text-white">Hi</span></div>'
      end

      it "sorts classes in each element" do
        # px-4 (spacing=4) < bg-red-500 (backgrounds=6)
        # text-white (typography=5) < rounded (borders=7)
        expect(Herb::Printer::IdentityPrinter.print(subject)).to eq(
          '<div class="px-4 bg-red-500"><span class="text-white rounded">Hi</span></div>'
        )
      end
    end

    context "with ERB interpolation in class attribute" do
      let(:source) { '<div class="<%= cls %> px-4">Hello</div>' }

      it "leaves mixed ERB attributes unchanged" do
        expect(Herb::Printer::IdentityPrinter.print(subject)).to eq(source)
      end
    end
  end
end
