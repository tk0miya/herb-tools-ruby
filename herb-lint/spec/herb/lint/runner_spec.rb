# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "herb/config"

RSpec.describe Herb::Lint::Runner do
  describe ".new" do
    let(:temp_custom_rules_dir) { File.join(Dir.tmpdir, "herb_test_no_custom_rules_#{Process.pid}") }
    let(:config) { Herb::Config::LinterConfig.new({ "linter" => { "custom_rules" => ["herb_test_no_custom_rules_rule"] } }) }

    before do
      FileUtils.mkdir_p(temp_custom_rules_dir)
      File.write(File.join(temp_custom_rules_dir, "herb_test_no_custom_rules_rule.rb"), <<~RUBY)
        class HerbTestNoCustomRulesRule < Herb::Lint::Rules::VisitorRule
          def self.rule_name = "test/no-custom-rules-rule"
          def self.description = "No custom rules test rule"
          def self.safe_autofixable? = false
          def self.unsafe_autofixable? = false
        end
      RUBY
      $LOAD_PATH.unshift(temp_custom_rules_dir)
    end

    after do
      $LOAD_PATH.delete(temp_custom_rules_dir)
      FileUtils.rm_rf(temp_custom_rules_dir)
    end

    context "when no_custom_rules: false (default)" do
      let(:runner) { described_class.new(config) }

      it "loads custom rules from configuration" do
        expect(runner.linter.rules.map { _1.class.rule_name }).to include("test/no-custom-rules-rule")
      end
    end

    context "when no_custom_rules: true" do
      let(:runner) { described_class.new(config, no_custom_rules: true) }

      it "skips loading custom rules" do
        expect(runner.linter.rules.map { _1.class.rule_name }).not_to include("test/no-custom-rules-rule")
      end
    end
  end

  describe "#run" do
    subject { runner.run(paths) }

    let(:runner) { described_class.new(config) }
    let(:safe_fixable_rule) { TestRules::SafeFixableRule }
    let(:unsafe_fixable_rule) { TestRules::UnsafeFixableRule }
    let(:config) { Herb::Config::LinterConfig.new(config_hash) }
    let(:config_hash) { { "linter" => linter_config } }
    let(:linter_config) { { "include" => include_patterns, "exclude" => exclude_patterns } }
    let(:include_patterns) { ["**/*.html.erb"] }
    let(:exclude_patterns) { [] }
    let(:paths) { [] }

    around do |example|
      Dir.mktmpdir do |temp_dir|
        Dir.chdir(temp_dir) do
          example.run
        end
      end
    end

    def create_file(relative_path, content = "")
      full_path = File.join(Dir.pwd, relative_path)
      FileUtils.mkdir_p(File.dirname(full_path))
      # Ensure content ends with newline if not empty
      content_with_newline = if content.empty? || content.end_with?("\n")
                               content
                             else
                               "#{content}\n"
                             end
      File.write(full_path, content_with_newline)
    end

    context "when discovering files from patterns" do
      before do
        create_file("app/views/users/index.html.erb", '<img src="test.png">')
        create_file("app/views/posts/show.html.erb", '<img src="image.png" alt="Image">')
        create_file("app/assets/application.js", "// javascript")
      end

      it "discovers files matching include patterns" do
        expect(subject.file_count).to eq(2)
      end

      it "returns an AggregatedResult" do
        expect(subject).to be_a(Herb::Lint::AggregatedResult)
      end
    end

    context "when discovering files from explicit paths" do
      let(:paths) { ["app/views/users/index.html.erb"] }

      before do
        create_file("app/views/users/index.html.erb", '<img src="test.png">')
        create_file("app/views/posts/show.html.erb", '<img src="image.png">')
      end

      it "processes only the specified files" do
        expect(subject.file_count).to eq(1)
      end
    end

    context "when processing multiple files" do
      before do
        create_file("app/views/a.html.erb", '<img src="a.png">')
        create_file("app/views/b.html.erb", '<img src="b.png">')
        create_file("app/views/c.html.erb", '<img src="c.png">')
      end

      it "processes all files and aggregates results" do
        expect(subject.file_count).to eq(3)
        expect(subject.offense_count).to eq(3) # Only html-img-require-alt
      end
    end

    context "when aggregating results" do
      before do
        create_file("app/views/valid.html.erb", '<img src="test.png" alt="Test">')
        create_file("app/views/invalid.html.erb", '<img src="test.png">')
      end

      it "aggregates offense counts correctly" do
        expect(subject.file_count).to eq(2)
        expect(subject.offense_count).to eq(1) # Only html-img-require-alt from invalid.html.erb
        expect(subject.error_count).to eq(1)
      end

      it "reports success correctly" do
        expect(subject.success?).to be(false)
      end
    end

    context "when all files are valid" do
      before do
        create_file("app/views/valid.html.erb", '<%= image_tag "test.png", alt: "Test" %>')
      end

      it "reports success" do
        expect(subject.success?).to be(true)
        expect(subject.offense_count).to eq(0)
      end
    end

    context "when no files match" do
      it "returns an empty result" do
        expect(subject.file_count).to eq(0)
        expect(subject.offense_count).to eq(0)
        expect(subject.success?).to be(true)
      end
    end

    context "with exclude patterns" do
      let(:exclude_patterns) { ["vendor/**/*"] }

      before do
        create_file("app/views/index.html.erb", '<img src="test.png">')
        create_file("vendor/gems/template.html.erb", '<img src="test.png">')
      end

      it "excludes files matching exclude patterns" do
        expect(subject.file_count).to eq(1)
      end
    end

    context "with autofix: true" do
      let(:rule_registry) { Herb::Lint::RuleRegistry.new(builtins: false, rules: [safe_fixable_rule, unsafe_fixable_rule], config:) }
      let(:runner) { described_class.new(config, autofix: true, rule_registry:) }

      context "with autofixable files" do
        it "applies safe fixes but not unsafe fixes, and preserves files without offenses" do
          # File with safe fixable offense
          create_file("app/views/safe.html.erb", "<div>content</div>")
          # File with unsafe fixable offense
          create_file("app/views/unsafe.html.erb", "<span>content</span>")
          # File without offenses
          create_file("app/views/clean.html.erb", "<p>content</p>")

          result = subject

          # Safe fix should be applied
          expect(File.read("app/views/safe.html.erb")).to eq("<div></div>\n")
          # Unsafe fix should NOT be applied
          expect(File.read("app/views/unsafe.html.erb")).to eq("<span>content</span>\n")
          # Clean file should not be modified
          expect(File.read("app/views/clean.html.erb")).to eq("<p>content</p>\n")
          # Only unfixed unsafe offense should remain
          expect(result.offense_count).to eq(1)
          # One offense was autofixed (the safe one)
          expect(result.autofixed_count).to eq(1)
          # One offense is still autofixable (the unsafe one)
          expect(result.autofixable_count).to eq(1)
        end
      end

      context "with broken files" do
        it "handles files with parse errors without crashing" do
          create_file("app/views/test.html.erb", "<% invalid ruby code")

          result = subject

          # Should report parse error, but not crash
          expect(result.offense_count).to be > 0
        end
      end
    end

    context "with autofix: true, unsafe: true" do
      let(:rule_registry) { Herb::Lint::RuleRegistry.new(builtins: false, rules: [safe_fixable_rule, unsafe_fixable_rule], config:) }
      let(:runner) { described_class.new(config, autofix: true, unsafe: true, rule_registry:) }

      it "applies both safe and unsafe fixes" do
        create_file("app/views/test.html.erb", "<div>content</div><span>content</span>")

        result = subject

        # Both fixes should be applied
        expect(File.read("app/views/test.html.erb")).to eq("<div></div><span></span>\n")
        expect(result.offense_count).to eq(0)
      end
    end

    context "with autofix: false" do
      let(:rule_registry) { Herb::Lint::RuleRegistry.new(builtins: false, rules: [safe_fixable_rule], config:) }
      let(:runner) { described_class.new(config, autofix: false, rule_registry:) }

      it "does not apply any fixes" do
        create_file("app/views/test.html.erb", "<div>content</div>")
        original_content = File.read("app/views/test.html.erb")

        result = subject

        # File should not be modified
        expect(File.read("app/views/test.html.erb")).to eq(original_content)
        # All offenses should be reported
        expect(result.offense_count).to eq(1)
      end
    end

    context "when tracking timing" do
      before do
        create_file("app/views/test.html.erb", '<img src="test.png" alt="Test">')
      end

      it "records start time and elapsed duration in the result" do
        expect(subject.start_time).to be_a(Time)
        expect(subject.duration).to be_a(Integer)
        expect(subject.duration).to be >= 0
      end
    end

    context "when linter is disabled in config" do
      let(:config_hash) { { "linter" => { "enabled" => false } } }

      before do
        create_file("app/views/test.html.erb", '<img src="test.png">')
      end

      it "returns a disabled result with timing and no offenses" do
        expect(subject.completed?).to be false
        expect(subject.message).to include("Linter is disabled")
        expect(subject.start_time).to be_a(Time)
        expect(subject.duration).to be_a(Integer)
        expect(subject.results).to be_empty
      end
    end

    context "when linter is disabled but force: true" do
      let(:config_hash) { { "linter" => { "enabled" => false, "include" => ["**/*.html.erb"] } } }
      let(:runner) { described_class.new(config, force: true) }

      before do
        create_file("app/views/test.html.erb", '<img src="test.png">')
      end

      it "runs linting despite disabled config" do
        expect(subject.completed?).to be true
        expect(subject.offense_count).to be > 0
      end
    end

    context "when tracking rule count" do
      context "with custom rules" do
        let(:rule_registry) { Herb::Lint::RuleRegistry.new(builtins: false, rules: [safe_fixable_rule, unsafe_fixable_rule], config:) }
        let(:runner) { described_class.new(config, rule_registry:) }

        it "tracks the number of active rules" do
          create_file("app/views/test.html.erb", "<div>content</div>")

          result = subject

          expect(result.rule_count).to eq(2)
        end
      end

      context "with all built-in rules" do
        let(:runner) { described_class.new(config) }

        it "tracks the count of all built-in rules" do
          create_file("app/views/test.html.erb", "<div>content</div>")

          result = subject

          # Should count all built-in rules (this number may change as rules are added)
          expect(result.rule_count).to be > 0
        end
      end
    end

    context "with force: true" do
      context "when a directory is excluded in config" do
        let(:config_hash) { { "linter" => { "exclude" => ["app/views/excluded/**"] } } }
        let(:config) { Herb::Config::LinterConfig.new(config_hash) }

        before { create_file("app/views/excluded/test.html.erb", "<img src=\"test.png\">\n") }

        context "when force: false (default)" do
          let(:runner) { described_class.new(config) }

          it "skips files in the excluded directory" do
            result = runner.run(["app/views/excluded"])
            expect(result.offenses).to be_empty
          end
        end

        context "when force: true with explicit directory path" do
          let(:runner) { described_class.new(config, force: true) }

          it "lints files in the excluded directory when force is specified" do
            result = runner.run(["app/views/excluded"])
            expect(result.offenses).not_to be_empty
          end
        end
      end
    end
  end

  describe "#config" do
    subject { runner.config }

    let(:runner) { described_class.new(config) }
    let(:config) { Herb::Config::LinterConfig.new({}) }

    it "returns the config passed to the initializer" do
      expect(subject).to eq(config)
    end
  end
end
