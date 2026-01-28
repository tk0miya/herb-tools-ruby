# frozen_string_literal: true

require "spec_helper"

RSpec.describe "End-to-end linting integration" do # rubocop:disable RSpec/DescribeClass
  let(:fixtures_path) { File.expand_path("../fixtures/templates", __dir__) }

  describe "linting fixture files" do
    context "with valid.html.erb" do
      subject { run_cli(fixture_path("valid.html.erb")) }

      it "reports no offenses" do
        expect(subject[:exit_code]).to eq(Herb::Lint::CLI::EXIT_SUCCESS)
        expect(subject[:stdout]).to include("0 problems")
      end
    end

    context "with missing_alt.html.erb" do
      subject { run_cli(fixture_path("missing_alt.html.erb")) }

      it "detects missing alt attribute offense" do
        expect(subject[:exit_code]).to eq(Herb::Lint::CLI::EXIT_LINT_ERROR)
        expect(subject[:stdout]).to include("alt-text")
        expect(subject[:stdout]).to include("Missing alt attribute")
      end
    end

    context "with unquoted_attributes.html.erb" do
      subject { run_cli(fixture_path("unquoted_attributes.html.erb")) }

      it "detects unquoted attribute offenses" do
        expect(subject[:exit_code]).to eq(Herb::Lint::CLI::EXIT_LINT_ERROR)
        expect(subject[:stdout]).to include("html/attribute-quotes")
      end
    end

    context "with mixed_issues.html.erb" do
      subject { run_cli(fixture_path("mixed_issues.html.erb")) }

      it "detects multiple offenses from different rules" do
        expect(subject[:exit_code]).to eq(Herb::Lint::CLI::EXIT_LINT_ERROR)
        expect(subject[:stdout]).to include("alt-text")
        expect(subject[:stdout]).to include("html/attribute-quotes")
      end
    end

    context "with parse_error.html.erb" do
      subject { run_cli(fixture_path("parse_error.html.erb")) }

      it "handles parse errors" do
        expect(subject[:stdout]).to include("parse-error")
      end
    end
  end

  describe "linting multiple files" do
    subject { run_cli(fixtures_path) }

    it "processes all files and aggregates offenses" do
      expect(subject[:exit_code]).to eq(Herb::Lint::CLI::EXIT_LINT_ERROR)
      expect(subject[:stdout]).to match(/\d+ problems.*in 5 files/)
    end
  end

  private

  def run_cli(*args)
    stdout = StringIO.new
    original_stdout = $stdout
    $stdout = stdout

    exit_code = Dir.chdir(fixtures_path) do
      Herb::Lint::CLI.new(args).run
    end

    { exit_code:, stdout: stdout.string }
  ensure
    $stdout = original_stdout
  end

  def fixture_path(filename)
    File.join(fixtures_path, filename)
  end
end
