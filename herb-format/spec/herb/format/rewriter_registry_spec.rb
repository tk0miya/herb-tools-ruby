# frozen_string_literal: true

require "fileutils"
require "spec_helper"

RSpec.describe Herb::Format::RewriterRegistry do
  let(:registry) { described_class.new }

  describe "#get" do
    subject { registry.get(name) }

    context "when the rewriter is registered" do
      let(:name) { "tailwind-class-sorter" }

      before { registry.load_builtin_rewriters }

      it { is_expected.to eq(Herb::Format::Rewriters::TailwindClassSorter) }
    end

    context "when the rewriter is not registered" do
      let(:name) { "unknown" }

      it { is_expected.to be_nil }
    end
  end

  describe "#load_builtin_rewriters" do
    subject { registry.load_builtin_rewriters }

    it "does not raise an error" do
      expect { subject }.not_to raise_error
    end

    it "registers TailwindClassSorter" do
      subject
      expect(registry.get("tailwind-class-sorter")).to eq(Herb::Format::Rewriters::TailwindClassSorter)
    end
  end

  describe "#load_custom_rewriters" do
    subject { registry.load_custom_rewriters(names) }

    context "with an empty list" do
      let(:names) { [] }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end

      it "does not register any rewriters" do
        subject
        expect(registry.get("custom-test-rewriter")).to be_nil
      end
    end

    context "with a file that defines a valid rewriter subclass" do
      let(:require_name) { "herb_format_test_custom_rewriter_#{Process.pid}" }
      let(:names) { [require_name] }
      let(:temp_dir) { File.join(Dir.tmpdir, "herb_test_custom_rewriters_#{Process.pid}") }

      before do
        FileUtils.mkdir_p(temp_dir)
        File.write(File.join(temp_dir, "#{require_name}.rb"), <<~RUBY)
          class HerbFormatTestCustomRewriter < Herb::Format::Rewriters::Base
            def self.rewriter_name = "custom-test-rewriter"
            def self.description = "Test custom rewriter"
            def self.phase = :post
            def rewrite(ast, _context) = ast
          end
        RUBY
        $LOAD_PATH.unshift(temp_dir)
      end

      after do
        $LOAD_PATH.delete(temp_dir)
        FileUtils.rm_rf(temp_dir)
      end

      it "registers the newly loaded rewriter" do
        subject
        expect(registry.get("custom-test-rewriter")).not_to be_nil
      end
    end

    context "with a require name that does not exist" do
      let(:names) { ["nonexistent_gem_that_does_not_exist"] }

      it "raises LoadError" do
        expect { subject }.to raise_error(LoadError)
      end
    end
  end
end
