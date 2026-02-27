# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Format::FormatterFactory do
  let(:config) { build(:formatter_config, indent_width: 4, max_line_length: 120) }
  let(:rewriter_registry) { instance_double(Herb::Rewriter::Registry) }
  let(:factory) { described_class.new(config, rewriter_registry) }

  describe "#initialize" do
    subject { described_class.new(config, rewriter_registry) }

    it "stores config and rewriter_registry as attributes" do
      expect(subject.config).to eq(config)
      expect(subject.rewriter_registry).to eq(rewriter_registry)
    end
  end

  describe "#create" do
    subject { factory.create }

    before do
      allow(rewriter_registry).to receive(:resolve_ast_rewriter).and_return(nil)
    end

    it "creates a Formatter instance" do
      expect(subject).to be_a(Herb::Format::Formatter)
    end

    it "creates formatter with the correct configuration" do
      expect(subject.config.indent_width).to eq(4)
      expect(subject.config.max_line_length).to eq(120)
    end

    context "when config has no rewriters" do
      it "creates formatter with empty pre- and post-rewriters" do
        expect(subject.pre_rewriters).to be_empty
        expect(subject.post_rewriters).to be_empty
      end
    end

    context "when config specifies pre-rewriters" do
      let(:rewriter_class) { Class.new(Herb::Rewriter::ASTRewriter) }
      let(:config) do
        Herb::Config::FormatterConfig.new(
          "formatter" => { "rewriter" => { "pre" => ["normalize-attributes"] } }
        )
      end

      before do
        allow(rewriter_registry).to receive(:resolve_ast_rewriter)
          .with("normalize-attributes").and_return(rewriter_class)
      end

      it "builds the pre-rewriters list" do
        expect(subject.pre_rewriters.size).to eq(1)
        expect(subject.pre_rewriters.first).to be_a(rewriter_class)
      end
    end

    context "when config specifies post-rewriters" do
      let(:rewriter_class) { Class.new(Herb::Rewriter::ASTRewriter) }
      let(:config) do
        Herb::Config::FormatterConfig.new(
          "formatter" => { "rewriter" => { "post" => ["tailwind-class-sorter"] } }
        )
      end

      before do
        allow(rewriter_registry).to receive(:resolve_ast_rewriter)
          .with("tailwind-class-sorter").and_return(rewriter_class)
      end

      it "builds the post-rewriters list" do
        expect(subject.post_rewriters.size).to eq(1)
        expect(subject.post_rewriters.first).to be_a(rewriter_class)
      end
    end

    context "when config references an unknown rewriter" do
      let(:config) do
        Herb::Config::FormatterConfig.new(
          "formatter" => { "rewriter" => { "pre" => ["unknown-rewriter"] } }
        )
      end

      before do
        allow(rewriter_registry).to receive(:resolve_ast_rewriter).with("unknown-rewriter").and_return(nil)
      end

      it "skips it and returns empty pre-rewriters" do
        expect(subject.pre_rewriters).to be_empty
      end
    end

    context "when a rewriter raises an error during instantiation" do
      let(:rewriter_class) do
        Class.new(Herb::Rewriter::ASTRewriter) do
          def initialize(options: {})
            super
            raise StandardError, "Initialization failed"
          end
        end
      end
      let(:config) do
        Herb::Config::FormatterConfig.new(
          "formatter" => { "rewriter" => { "pre" => ["broken-rewriter"] } }
        )
      end

      before do
        allow(rewriter_registry).to receive(:resolve_ast_rewriter).with("broken-rewriter").and_return(rewriter_class)
      end

      it "skips the broken rewriter and warns to stderr" do
        expect do
          result = subject
          expect(result.pre_rewriters).to be_empty
        end.to output(/Failed to instantiate rewriter/).to_stderr
      end
    end
  end
end
