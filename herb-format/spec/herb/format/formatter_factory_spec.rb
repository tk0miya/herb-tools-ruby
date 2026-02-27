# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Format::FormatterFactory do
  let(:config) { build(:formatter_config, indent_width: 4, max_line_length: 120) }
  let(:rewriter_registry) { Herb::Rewriter::Registry.new }
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
      let(:config) do
        Herb::Config::FormatterConfig.new(
          "formatter" => { "rewriter" => { "pre" => ["tailwind-class-sorter"] } }
        )
      end

      it "builds the pre-rewriters list" do
        expect(subject.pre_rewriters.size).to eq(1)
        expect(subject.pre_rewriters.first).to be_a(Herb::Rewriter::BuiltIns::TailwindClassSorter)
      end
    end

    context "when config specifies post-rewriters" do
      let(:rewriter_class) do
        Class.new(Herb::Rewriter::StringRewriter) do
          def self.rewriter_name = "custom-string-rewriter"
        end
      end
      let(:config) do
        Herb::Config::FormatterConfig.new(
          "formatter" => { "rewriter" => { "post" => ["custom-string-rewriter"] } }
        )
      end

      before { rewriter_registry.send(:register, rewriter_class) }

      it "builds the post-rewriters list" do
        expect(subject.post_rewriters.size).to eq(1)
        expect(subject.post_rewriters.first).to be_a(rewriter_class)
      end
    end

    context "when config references an unknown pre-rewriter" do
      let(:config) do
        Herb::Config::FormatterConfig.new(
          "formatter" => { "rewriter" => { "pre" => ["unknown-rewriter"] } }
        )
      end

      it "skips it, returns empty pre-rewriters, and warns to stderr" do
        expect { subject }.to output(/Pre-format rewriter 'unknown-rewriter' not found/).to_stderr
        expect(subject.pre_rewriters).to be_empty
      end
    end

    context "when config references an unknown post-rewriter" do
      let(:config) do
        Herb::Config::FormatterConfig.new(
          "formatter" => { "rewriter" => { "post" => ["unknown-rewriter"] } }
        )
      end

      it "skips it, returns empty post-rewriters, and warns to stderr" do
        expect { subject }.to output(/Post-format rewriter 'unknown-rewriter' not found/).to_stderr
        expect(subject.post_rewriters).to be_empty
      end
    end

    context "when a pre-rewriter raises an error during instantiation" do
      let(:rewriter_class) do
        Class.new(Herb::Rewriter::ASTRewriter) do
          def self.rewriter_name = "broken-rewriter"

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

      before { rewriter_registry.send(:register, rewriter_class) }

      it "skips the broken rewriter and warns to stderr" do
        expect { subject }.to output(/Failed to instantiate pre-format rewriter/).to_stderr
        expect(subject.pre_rewriters).to be_empty
      end
    end

    context "when a post-rewriter raises an error during instantiation" do
      let(:rewriter_class) do
        Class.new(Herb::Rewriter::StringRewriter) do
          def self.rewriter_name = "broken-string-rewriter"

          def initialize
            super
            raise StandardError, "Initialization failed"
          end
        end
      end
      let(:config) do
        Herb::Config::FormatterConfig.new(
          "formatter" => { "rewriter" => { "post" => ["broken-string-rewriter"] } }
        )
      end

      before { rewriter_registry.send(:register, rewriter_class) }

      it "skips the broken rewriter and warns to stderr" do
        expect { subject }.to output(/Failed to instantiate post-format rewriter/).to_stderr
        expect(subject.post_rewriters).to be_empty
      end
    end
  end
end
