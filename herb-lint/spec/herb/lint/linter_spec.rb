# frozen_string_literal: true

require "herb/config"

RSpec.describe Herb::Lint::Linter do
  let(:linter) { described_class.new(rules, config, rule_registry:) }
  let(:config) { Herb::Config::LinterConfig.new(config_hash) }
  let(:config_hash) { {} }
  let(:rule_registry) { Herb::Lint::RuleRegistry.new }

  describe "#lint" do
    subject { linter.lint(file_path:, source:) }

    let(:file_path) { "app/views/users/index.html.erb" }

    context "with rules that detect offenses" do
      let(:rules) { [Herb::Lint::Rules::HtmlImgRequireAlt.new] }
      let(:source) { '<img src="test.png">' }

      it "returns a LintResult with offenses" do
        expect(subject).to be_a(Herb::Lint::LintResult)
        expect(subject.file_path).to eq(file_path)
        expect(subject.source).to eq(source)
        expect(subject.offenses.size).to eq(1)
        expect(subject.offenses.first.rule_name).to eq("alt-text")
      end
    end

    context "with rules that find no offenses" do
      let(:rules) { [Herb::Lint::Rules::HtmlImgRequireAlt.new] }
      let(:source) { '<img src="test.png" alt="A test image">' }

      it "returns a LintResult with empty offenses" do
        expect(subject).to be_a(Herb::Lint::LintResult)
        expect(subject.file_path).to eq(file_path)
        expect(subject.offenses).to be_empty
      end
    end

    context "with multiple rules" do
      let(:rules) do
        [
          Herb::Lint::Rules::HtmlImgRequireAlt.new,
          test_rule_class.new
        ]
      end
      let(:test_rule_class) do
        Class.new(Herb::Lint::Rules::VisitorRule) do
          def self.rule_name = "test-rule"
          def self.description = "Test rule"

          def visit_html_element_node(node)
            add_offense(message: "Found element", location: node.location)
            super
          end
        end
      end
      let(:source) { '<img src="test.png">' }

      it "collects offenses from all rules" do
        expect(subject.offenses.size).to eq(2)

        rule_names = subject.offenses.map(&:rule_name)
        expect(rule_names).to contain_exactly("alt-text", "test-rule")
      end
    end

    context "with no rules" do
      let(:rules) { [] }
      let(:source) { '<img src="test.png">' }

      it "returns a LintResult with no offenses" do
        expect(subject.offenses).to be_empty
      end
    end

    context "when source has parse errors" do
      let(:rules) { [Herb::Lint::Rules::HtmlImgRequireAlt.new] }
      let(:source) { "<%= unclosed" }

      it "returns a LintResult with parse-error offenses" do
        expect(subject).to be_a(Herb::Lint::LintResult)
        expect(subject.file_path).to eq(file_path)
        expect(subject.source).to eq(source)
        expect(subject.offenses).not_to be_empty
        expect(subject.offenses.first.rule_name).to eq("parse-error")
        expect(subject.offenses.first.severity).to eq("error")
      end
    end
  end

  describe "#rules" do
    let(:rules) { [Herb::Lint::Rules::HtmlImgRequireAlt.new] }

    it "returns the rules passed to the initializer" do
      expect(linter.rules).to eq(rules)
    end
  end

  describe "#config" do
    let(:rules) { [] }

    it "returns the config passed to the initializer" do
      expect(linter.config).to eq(config)
    end
  end
end
