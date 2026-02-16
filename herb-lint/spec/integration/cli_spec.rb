# frozen_string_literal: true

require "spec_helper"
require "open3"
require "tmpdir"
require "fileutils"
require "yaml"

RSpec.describe "CLI integration" do # rubocop:disable RSpec/DescribeClass
  let(:fixtures_path) { File.expand_path("../fixtures/templates", __dir__) }

  describe "--version flag" do
    subject { run_cli("--version") }

    it "outputs version and exits with success code" do
      expect(subject[:stdout]).to match(/herb-lint \d+\.\d+\.\d+/)
      expect(subject[:status].exitstatus).to eq(Herb::Lint::CLI::EXIT_SUCCESS)
    end
  end

  describe "--help flag" do
    subject { run_cli("--help") }

    it "outputs help text and exits with success code" do
      expect(subject[:stdout]).to include("Usage:")
      expect(subject[:status].exitstatus).to eq(Herb::Lint::CLI::EXIT_SUCCESS)
    end
  end

  describe "--init flag" do
    let(:temp_dir) { Dir.mktmpdir }

    around do |example|
      Dir.chdir(temp_dir) do
        example.run
      end
    ensure
      FileUtils.remove_entry(temp_dir) if temp_dir && File.exist?(temp_dir)
    end

    def run_init_in_tempdir(temp_directory, *args)
      herb_lint_path = File.expand_path("../../exe/herb-lint", __dir__)
      root_dir = File.expand_path("../..", __dir__)
      # Run in the temp directory, not the root
      Dir.chdir(temp_directory) do
        stdout, stderr, status = Open3.capture3(
          { "BUNDLE_GEMFILE" => File.join(root_dir, "Gemfile") },
          "bundle", "exec", herb_lint_path, *args
        )
        { stdout:, stderr:, status: }
      end
    end

    context "when .herb.yml does not exist" do
      it "creates .herb.yml and exits with success code" do
        result = run_init_in_tempdir(temp_dir, "--init")
        expect(result[:stdout]).to include("Created .herb.yml")
        expect(result[:status].exitstatus).to eq(Herb::Lint::CLI::EXIT_SUCCESS)
        expect(File.exist?(File.join(temp_dir, ".herb.yml"))).to be true
      end

      it "creates valid YAML configuration" do
        run_init_in_tempdir(temp_dir, "--init")
        config_path = File.join(temp_dir, ".herb.yml")
        config = YAML.safe_load_file(config_path, permitted_classes: [Symbol])
        expect(config).to have_key("linter")
        expect(config).to have_key("formatter")
      end
    end

    context "when .herb.yml already exists" do
      before do
        File.write(File.join(temp_dir, ".herb.yml"), "existing: config")
      end

      it "reports error and exits with runtime error code" do
        result = run_init_in_tempdir(temp_dir, "--init")
        expect(result[:stderr]).to include("Error: .herb.yml already exists")
        expect(result[:status].exitstatus).to eq(Herb::Lint::CLI::EXIT_RUNTIME_ERROR)
      end

      it "does not overwrite existing file" do
        run_init_in_tempdir(temp_dir, "--init")
        config_path = File.join(temp_dir, ".herb.yml")
        expect(File.read(config_path)).to eq("existing: config")
      end
    end
  end

  describe "linting files" do
    context "with valid file" do
      subject { run_cli(fixture_path("valid.html.erb")) }

      it "reports no problems and exits with success code" do
        expect(subject[:stdout]).to include("Summary:")
        expect(subject[:stdout]).to include("0 offenses")
        expect(subject[:status].exitstatus).to eq(Herb::Lint::CLI::EXIT_SUCCESS)
      end
    end

    context "with file containing offenses" do
      subject { run_cli(fixture_path("missing_alt.html.erb")) }

      it "reports offenses and exits with lint error code" do
        expect(subject[:stdout]).to include("html-img-require-alt")
        expect(subject[:stdout]).to include("Summary:")
        expect(subject[:stdout]).to include("1 error")
        expect(subject[:stdout]).to include("Offenses")
        expect(subject[:status].exitstatus).to eq(Herb::Lint::CLI::EXIT_LINT_ERROR)
      end
    end

    context "with multiple files containing issues" do
      subject { run_cli(fixtures_path) }

      it "processes all files, reports offenses, and exits with lint error code" do
        expect(subject[:stdout]).to include("Summary:")
        expect(subject[:stdout]).to include("Offenses")
        expect(subject[:stdout]).to include("errors")
        expect(subject[:status].exitstatus).to eq(Herb::Lint::CLI::EXIT_LINT_ERROR)
      end
    end
  end

  describe "output format" do
    subject { run_cli(fixture_path("mixed_issues.html.erb")) }

    it "includes file path, line/column, severity, rule name, and summary" do
      output = subject[:stdout].force_encoding("UTF-8")
      expect(output).to include("mixed_issues.html.erb")
      expect(output).to match(/\d+:\d+/)
      expect(output).to match(/✗|⚠|ℹ/)
      expect(output).to match(/html-img-require-alt|html-attribute-double-quotes/)
      # Check for TypeScript-style summary format
      expect(output).to include("Summary:")
      expect(output).to include("Checked")
      expect(output).to include("Offenses")
    end
  end

  private

  def run_cli(*args)
    herb_lint_path = File.expand_path("../../exe/herb-lint", __dir__)
    Dir.chdir(File.expand_path("../..", __dir__)) do
      stdout, stderr, status = Open3.capture3("bundle", "exec", herb_lint_path, *args)
      { stdout:, stderr:, status: }
    end
  end

  def fixture_path(filename)
    File.join(fixtures_path, filename)
  end
end
