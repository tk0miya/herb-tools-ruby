# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Format::RewriterRegistry do
  let(:registry) { described_class.new }

  let(:test_rewriter_class) do
    Class.new(Herb::Format::Rewriters::Base) do
      def self.rewriter_name = "test-rewriter"
      def self.description = "Test rewriter"
      def self.phase = :post
      def rewrite(ast, _context) = ast
    end
  end

  describe "#register" do
    subject { registry.register(test_rewriter_class) }

    context "with a valid Base subclass" do
      it "registers the rewriter class" do
        subject
        expect(registry.registered?("test-rewriter")).to be true
      end
    end

    context "with a non-Base subclass" do
      let(:test_rewriter_class) { Class.new }

      it "raises RewriterError" do
        expect { subject }.to raise_error(Herb::Format::Errors::RewriterError, /must inherit/)
      end
    end

    context "with a class missing rewriter_name" do
      let(:test_rewriter_class) { Class.new(Herb::Format::Rewriters::Base) }

      it "raises RewriterError" do
        expect { subject }.to raise_error(Herb::Format::Errors::RewriterError, /missing required method/)
      end
    end
  end

  describe "#get" do
    subject { registry.get(name) }

    context "when the rewriter is registered" do
      let(:name) { "test-rewriter" }

      before { registry.register(test_rewriter_class) }

      it { is_expected.to eq(test_rewriter_class) }
    end

    context "when the rewriter is not registered" do
      let(:name) { "unknown" }

      it { is_expected.to be_nil }
    end
  end

  describe "#registered?" do
    subject { registry.registered?(name) }

    context "when the rewriter is registered" do
      let(:name) { "test-rewriter" }

      before { registry.register(test_rewriter_class) }

      it { is_expected.to be true }
    end

    context "when the rewriter is not registered" do
      let(:name) { "unknown" }

      it { is_expected.to be false }
    end
  end

  describe "#all" do
    subject { registry.all }

    context "with registered rewriters" do
      before { registry.register(test_rewriter_class) }

      it { is_expected.to eq([test_rewriter_class]) }
    end

    context "with no registered rewriters" do
      it { is_expected.to eq([]) }
    end
  end

  describe "#rewriter_names" do
    subject { registry.rewriter_names }

    context "with registered rewriters" do
      before { registry.register(test_rewriter_class) }

      it { is_expected.to eq(["test-rewriter"]) }
    end

    context "with no registered rewriters" do
      it { is_expected.to eq([]) }
    end
  end

  describe "#load_builtin_rewriters" do
    subject { registry.load_builtin_rewriters }

    it "does not raise an error" do
      expect { subject }.not_to raise_error
    end

    it "registers TailwindClassSorter" do
      subject
      expect(registry.registered?("tailwind-class-sorter")).to be true
    end
  end
end
