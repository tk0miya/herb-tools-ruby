# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe Herb::Lint::CustomRuleLoader do
  let(:config) { Herb::Config::LinterConfig.new({}) }
  let(:registry) { Herb::Lint::RuleRegistry.new(config:, builtins: false) }
  let(:loader) { described_class.new(registry, base_dir:) }

  describe "#discover_rule_files" do
    context "with custom rules directory" do
      let(:base_dir) { Dir.mktmpdir("test_project") }

      before do
        FileUtils.mkdir_p(File.join(base_dir, ".herb/rules"))
        FileUtils.touch(File.join(base_dir, ".herb/rules/my_rule.rb"))
        FileUtils.touch(File.join(base_dir, ".herb/rules/another_rule.rb"))
      end

      after do
        FileUtils.rm_rf(base_dir)
      end

      it "discovers rule files" do
        files = loader.discover_rule_files
        expect(files.size).to eq(2)
        expect(files).to all(end_with(".rb"))
        expect(files).to include(end_with("my_rule.rb"), end_with("another_rule.rb"))
      end
    end

    context "with nested custom rules directory" do
      let(:base_dir) { Dir.mktmpdir("test_project") }

      before do
        FileUtils.mkdir_p(File.join(base_dir, ".herb/rules/custom"))
        FileUtils.touch(File.join(base_dir, ".herb/rules/custom/nested_rule.rb"))
      end

      after do
        FileUtils.rm_rf(base_dir)
      end

      it "discovers nested rule files" do
        files = loader.discover_rule_files
        expect(files.size).to eq(1)
        expect(files.first).to end_with("nested_rule.rb")
      end
    end

    context "without custom rules directory" do
      let(:base_dir) { Dir.mktmpdir("empty_project") }

      after do
        FileUtils.rm_rf(base_dir)
      end

      it "returns empty array" do
        files = loader.discover_rule_files
        expect(files).to be_empty
      end
    end
  end

  describe "#load_rule_file" do
    let(:base_dir) { Dir.mktmpdir("test_project") }

    after do
      FileUtils.rm_rf(base_dir)
    end

    context "with valid rule file" do
      let(:rule_file_path) { File.join(base_dir, "test_rule.rb") }

      before do
        FileUtils.mkdir_p(base_dir)
        File.write(rule_file_path, <<~RUBY)
          module Herb
            module Lint
              module Rules
                class TestCustomRule < VisitorRule
                  def self.rule_name = "test-custom-rule"
                  def self.description = "A test custom rule"
                  def self.safe_autofixable? = false
                  def self.unsafe_autofixable? = false
                end
              end
            end
          end
        RUBY
      end

      it "loads and returns the rule class" do
        rules = loader.load_rule_file(rule_file_path)
        expect(rules.size).to eq(1)
        expect(rules.first.rule_name).to eq("test-custom-rule")
        expect(rules.first.description).to eq("A test custom rule")
      end
    end

    context "with invalid Ruby file" do
      let(:rule_file_path) { File.join(base_dir, "invalid_rule.rb") }

      before do
        FileUtils.mkdir_p(base_dir)
        File.write(rule_file_path, "this is not valid ruby !!!")
      end

      it "returns empty array and warns" do
        expect { loader.load_rule_file(rule_file_path) }
          .to output(/Failed to load rule file/).to_stderr
        rules = loader.load_rule_file(rule_file_path)
        expect(rules).to be_empty
      end
    end

    context "with silent mode" do
      let(:rule_file_path) { File.join(base_dir, "invalid_rule.rb") }
      let(:loader) { described_class.new(registry, base_dir:, silent: true) }

      before do
        FileUtils.mkdir_p(base_dir)
        File.write(rule_file_path, "this is not valid ruby !!!")
      end

      it "does not output warnings" do
        expect { loader.load_rule_file(rule_file_path) }
          .not_to output.to_stderr
      end
    end
  end

  describe "#load_rules_with_info" do
    let(:base_dir) { Dir.mktmpdir("test_project") }

    after do
      FileUtils.rm_rf(base_dir)
    end

    context "with multiple rule files" do
      before do
        FileUtils.mkdir_p(File.join(base_dir, ".herb/rules"))

        File.write(File.join(base_dir, ".herb/rules/rule1.rb"), <<~RUBY)
          module Herb
            module Lint
              module Rules
                class CustomRule1 < VisitorRule
                  def self.rule_name = "custom-rule-1"
                  def self.description = "First custom rule"
                  def self.safe_autofixable? = false
                  def self.unsafe_autofixable? = false
                end
              end
            end
          end
        RUBY

        File.write(File.join(base_dir, ".herb/rules/rule2.rb"), <<~RUBY)
          module Herb
            module Lint
              module Rules
                class CustomRule2 < VisitorRule
                  def self.rule_name = "custom-rule-2"
                  def self.description = "Second custom rule"
                  def self.safe_autofixable? = false
                  def self.unsafe_autofixable? = false
                end
              end
            end
          end
        RUBY
      end

      it "loads all rules and returns info" do
        result = loader.load_rules_with_info

        expect(result.rules.size).to eq(2)
        expect(result.rule_info.size).to eq(2)
        expect(result.duplicate_warnings).to be_empty

        rule_names = result.rule_info.map(&:name)
        expect(rule_names).to contain_exactly("custom-rule-1", "custom-rule-2")
      end
    end

    context "with duplicate rule names" do
      before do
        FileUtils.mkdir_p(File.join(base_dir, ".herb/rules"))

        File.write(File.join(base_dir, ".herb/rules/rule1.rb"), <<~RUBY)
          module Herb
            module Lint
              module Rules
                class DuplicateRule1 < VisitorRule
                  def self.rule_name = "duplicate-rule"
                  def self.description = "First duplicate rule"
                  def self.safe_autofixable? = false
                  def self.unsafe_autofixable? = false
                end
              end
            end
          end
        RUBY

        File.write(File.join(base_dir, ".herb/rules/rule2.rb"), <<~RUBY)
          module Herb
            module Lint
              module Rules
                class DuplicateRule2 < VisitorRule
                  def self.rule_name = "duplicate-rule"
                  def self.description = "Second duplicate rule"
                  def self.safe_autofixable? = false
                  def self.unsafe_autofixable? = false
                end
              end
            end
          end
        RUBY
      end

      it "detects duplicates and warns" do
        result = loader.load_rules_with_info

        expect(result.rules.size).to eq(2)
        expect(result.duplicate_warnings.size).to eq(1)
        expect(result.duplicate_warnings.first).to include("duplicate-rule")
        expect(result.duplicate_warnings.first).to include("multiple files")
      end
    end

    context "without custom rules" do
      it "returns empty result" do
        result = loader.load_rules_with_info

        expect(result.rules).to be_empty
        expect(result.rule_info).to be_empty
        expect(result.duplicate_warnings).to be_empty
      end
    end
  end

  describe ".has_custom_rules?" do
    context "with custom rules" do
      let(:base_dir) { Dir.mktmpdir("project_with_rules") }

      before do
        FileUtils.mkdir_p(File.join(base_dir, ".herb/rules"))
        FileUtils.touch(File.join(base_dir, ".herb/rules/custom.rb"))
      end

      after do
        FileUtils.rm_rf(base_dir)
      end

      it "returns true" do
        expect(described_class.has_custom_rules?(base_dir:)).to be true
      end
    end

    context "without custom rules" do
      let(:base_dir) { Dir.mktmpdir("project_without_rules") }

      after do
        FileUtils.rm_rf(base_dir)
      end

      it "returns false" do
        expect(described_class.has_custom_rules?(base_dir:)).to be false
      end
    end
  end
end
