# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Herb::Rewriter::Registry do
  let(:custom_ast_rewriter) do
    Class.new(Herb::Rewriter::ASTRewriter) do
      def self.rewriter_name = "custom-ast-rewriter"
      def self.description = "A custom AST rewriter for testing"
      def rewrite(ast, _context) = ast
    end
  end

  let(:custom_string_rewriter) do
    Class.new(Herb::Rewriter::StringRewriter) do
      def self.rewriter_name = "custom-string-rewriter"
      def self.description = "A custom string rewriter for testing"
      def rewrite(formatted, _context) = formatted
    end
  end

  let(:registry) { described_class.new }

  describe "#registered?" do
    subject { registry.registered?(name) }

    context "when the name is a built-in AST rewriter" do
      let(:name) { "tailwind-class-sorter" }

      it { is_expected.to be true }
    end

    context "when the name is a custom AST rewriter" do
      let(:name) { "custom-ast-rewriter" }

      before { registry.send(:register, custom_ast_rewriter) }

      it { is_expected.to be true }
    end

    context "when the name is a custom string rewriter" do
      let(:name) { "custom-string-rewriter" }

      before { registry.send(:register, custom_string_rewriter) }

      it { is_expected.to be true }
    end

    context "when the name is unknown" do
      let(:name) { "nonexistent" }

      it { is_expected.to be false }
    end
  end

  describe "#resolve_ast_rewriter" do
    subject { registry.resolve_ast_rewriter(name) }

    context "when the name matches a built-in AST rewriter" do
      let(:name) { "tailwind-class-sorter" }

      it { is_expected.to eq(Herb::Rewriter::BuiltIns::TailwindClassSorter) }
    end

    context "when the name matches a custom AST rewriter" do
      let(:name) { "custom-ast-rewriter" }

      before { registry.send(:register, custom_ast_rewriter) }

      it { is_expected.to eq(custom_ast_rewriter) }
    end

    context "when a custom AST rewriter shadows a built-in with the same name" do
      let(:name) { "tailwind-class-sorter" }
      let(:shadow_rewriter) do
        Class.new(Herb::Rewriter::ASTRewriter) do
          def self.rewriter_name = "tailwind-class-sorter"
          def self.description = "Shadow rewriter"
          def rewrite(ast, _context) = ast
        end
      end

      before { registry.send(:register, shadow_rewriter) }

      it { is_expected.to eq(shadow_rewriter) }
    end

    context "when require succeeds and defines a new ASTRewriter subclass" do
      let(:temp_dir) { Dir.mktmpdir }
      let(:rewriter_file) { File.join(temp_dir, "resolve-ast-rewriter.rb") }

      before do
        File.write(rewriter_file, <<~RUBY)
          module Herb
            module Rewriter
              class ResolveASTRewriter < ASTRewriter
                def self.rewriter_name = "resolve-ast-rewriter"
                def self.description = "Auto-discovered AST rewriter for testing"
                def rewrite(ast, _context) = ast
              end
            end
          end
        RUBY
      end

      after { FileUtils.rm_rf(temp_dir) }

      it "discovers, returns, and registers the new ASTRewriter subclass" do
        result = registry.resolve_ast_rewriter(rewriter_file)
        expect(result).to eq(Herb::Rewriter::ResolveASTRewriter)
        expect(registry.registered?("resolve-ast-rewriter")).to be true
      end
    end

    context "when the name is a file path (basename matches rewriter_name)" do
      let(:temp_dir) { Dir.mktmpdir }
      let(:rewriter_file) { File.join(temp_dir, "my-ast-rewriter.rb") }

      before do
        File.write(rewriter_file, <<~RUBY)
          module Herb
            module Rewriter
              class MyASTRewriterViaPath < ASTRewriter
                def self.rewriter_name = "my-ast-rewriter"
                def self.description = "AST rewriter loaded via file path"
                def rewrite(ast, _context) = ast
              end
            end
          end
        RUBY
      end

      after { FileUtils.rm_rf(temp_dir) }

      it "resolves the rewriter class and marks it as registered" do
        result = registry.resolve_ast_rewriter(rewriter_file)
        expect(result).to eq(Herb::Rewriter::MyASTRewriterViaPath)
        expect(registry.registered?("my-ast-rewriter")).to be true
      end
    end

    context "when the name is unknown and require fails" do
      let(:name) { "nonexistent-gem-that-does-not-exist-abc123" }

      it { is_expected.to be_nil }
    end
  end

  describe "#resolve_string_rewriter" do
    subject { registry.resolve_string_rewriter(name) }

    context "when the name matches a custom string rewriter" do
      let(:name) { "custom-string-rewriter" }

      before { registry.send(:register, custom_string_rewriter) }

      it { is_expected.to eq(custom_string_rewriter) }
    end

    context "when require succeeds and defines a new StringRewriter subclass" do
      let(:temp_dir) { Dir.mktmpdir }
      let(:rewriter_file) { File.join(temp_dir, "resolve-string-rewriter.rb") }

      before do
        File.write(rewriter_file, <<~RUBY)
          module Herb
            module Rewriter
              class ResolveStringRewriter < StringRewriter
                def self.rewriter_name = "resolve-string-rewriter"
                def self.description = "Auto-discovered string rewriter for testing"
                def rewrite(formatted, _context) = formatted
              end
            end
          end
        RUBY
      end

      after { FileUtils.rm_rf(temp_dir) }

      it "discovers, returns, and registers the new StringRewriter subclass" do
        result = registry.resolve_string_rewriter(rewriter_file)
        expect(result).to eq(Herb::Rewriter::ResolveStringRewriter)
        expect(registry.registered?("resolve-string-rewriter")).to be true
      end
    end

    context "when the name is a file path (basename matches rewriter_name)" do
      let(:temp_dir) { Dir.mktmpdir }
      let(:rewriter_file) { File.join(temp_dir, "my-string-rewriter.rb") }

      before do
        File.write(rewriter_file, <<~RUBY)
          module Herb
            module Rewriter
              class MyStringRewriterViaPath < StringRewriter
                def self.rewriter_name = "my-string-rewriter"
                def self.description = "String rewriter loaded via file path"
                def rewrite(formatted, _context) = formatted
              end
            end
          end
        RUBY
      end

      after { FileUtils.rm_rf(temp_dir) }

      it "resolves the rewriter class and marks it as registered" do
        result = registry.resolve_string_rewriter(rewriter_file)
        expect(result).to eq(Herb::Rewriter::MyStringRewriterViaPath)
        expect(registry.registered?("my-string-rewriter")).to be true
      end
    end

    context "when the name is unknown and require fails" do
      let(:name) { "nonexistent-gem-that-does-not-exist-abc123" }

      it { is_expected.to be_nil }
    end
  end
end
