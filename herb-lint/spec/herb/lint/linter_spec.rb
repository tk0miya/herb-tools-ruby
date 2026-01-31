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
        expect(subject.offenses.first.rule_name).to eq("html-img-require-alt")
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
        expect(rule_names).to contain_exactly("html-img-require-alt", "test-rule")
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

    context "when file has herb:linter ignore directive" do
      let(:rules) { [Herb::Lint::Rules::HtmlImgRequireAlt.new] }
      let(:source) { "<%# herb:linter ignore %>\n<img src=\"test.png\">" }

      it "returns an empty result" do
        expect(subject.offenses).to be_empty
        expect(subject.ignored_count).to eq(0)
      end
    end

    context "when offense is disabled on the same line" do
      let(:rules) { [Herb::Lint::Rules::HtmlImgRequireAlt.new] }
      let(:source) { '<img src="test.png"> <%# herb:disable html-img-require-alt %>' }

      it "filters out the disabled offense" do
        expect(subject.offenses).to be_empty
        expect(subject.ignored_count).to eq(1)
      end
    end

    context "when offense is disabled with all" do
      let(:rules) { [Herb::Lint::Rules::HtmlImgRequireAlt.new] }
      let(:source) { '<img src="test.png"> <%# herb:disable all %>' }

      it "filters out all offenses on that line" do
        expect(subject.offenses).to be_empty
        expect(subject.ignored_count).to eq(1)
      end
    end

    context "when a different rule is disabled" do
      let(:rules) { [Herb::Lint::Rules::HtmlImgRequireAlt.new] }
      let(:source) { '<img src="test.png"> <%# herb:disable html-no-self-closing %>' }

      it "does not filter the offense" do
        expect(subject.offenses.size).to eq(1)
        expect(subject.offenses.first.rule_name).to eq("html-img-require-alt")
        expect(subject.ignored_count).to eq(0)
      end
    end

    context "when disable is on a different line" do
      let(:rules) { [Herb::Lint::Rules::HtmlImgRequireAlt.new] }
      let(:source) { "<%# herb:disable html-img-require-alt %>\n<img src=\"test.png\">" }

      it "does not filter the offense on the other line" do
        expect(subject.offenses.size).to eq(1)
        expect(subject.ignored_count).to eq(0)
      end
    end

    context "with ignore_disable_comments option" do
      let(:linter) { described_class.new(rules, config, rule_registry:, ignore_disable_comments: true) }
      let(:rules) { [Herb::Lint::Rules::HtmlImgRequireAlt.new] }
      let(:source) { '<img src="test.png"> <%# herb:disable html-img-require-alt %>' }

      it "reports all offenses regardless of directives" do
        expect(subject.offenses.size).to eq(1)
        expect(subject.offenses.first.rule_name).to eq("html-img-require-alt")
        expect(subject.ignored_count).to eq(0)
      end
    end

    context "with mixed disabled and enabled offenses" do
      let(:rules) { [Herb::Lint::Rules::HtmlImgRequireAlt.new] }
      let(:source) do
        <<~ERB.chomp
          <img src="a.png"> <%# herb:disable html-img-require-alt %>
          <img src="b.png">
        ERB
      end

      it "only reports the non-disabled offense" do
        expect(subject.offenses.size).to eq(1)
        expect(subject.offenses.first.line).to eq(2)
        expect(subject.ignored_count).to eq(1)
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
