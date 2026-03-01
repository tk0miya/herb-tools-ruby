# frozen_string_literal: true

RSpec.describe Herb::Format::CLI do
  describe "#run" do
    subject { cli.run }

    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }
    let(:stdin) { StringIO.new }
    let(:cli) { described_class.new(argv, stdout:, stderr:, stdin:) }
    let(:argv) { [] }

    around do |example|
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) { example.run }
      end
    end

    context "with --version" do
      let(:argv) { ["--version"] }

      it "exits successfully and displays version" do
        expect(subject).to eq(described_class::EXIT_SUCCESS)
        expect(stdout.string).to include(Herb::Format::VERSION)
      end
    end

    context "with --help" do
      let(:argv) { ["--help"] }

      it "exits successfully and displays usage" do
        expect(subject).to eq(described_class::EXIT_SUCCESS)
        expect(stdout.string).to include("Usage:")
      end
    end

    context "with --init" do
      let(:argv) { ["--init"] }

      context "when .herb.yml does not exist" do
        it "creates .herb.yml and exits successfully" do
          expect(subject).to eq(described_class::EXIT_SUCCESS)
          expect(File.exist?(".herb.yml")).to be true
          expect(stdout.string).to include("Created .herb.yml")
        end
      end

      context "when .herb.yml already exists" do
        before { File.write(".herb.yml", "# existing") }

        it "fails with runtime error" do
          expect(subject).to eq(described_class::EXIT_RUNTIME_ERROR)
          expect(stderr.string).to include("already exists")
        end
      end
    end

    context "with stdin via '-'" do
      let(:argv) { ["-"] }
      let(:stdin) { StringIO.new("<div><p>Hello</p></div>") }

      before { File.write(".herb.yml", "formatter:\n  enabled: true\n") }

      it "formats content to stdout with trailing newline" do
        expect(subject).to eq(described_class::EXIT_SUCCESS)
        expect(stdout.string).to eq("<div>\n  <p>Hello</p>\n</div>\n")
      end
    end

    context "with -c (shorthand for --check)" do
      let(:argv) { ["-c", "test.html.erb"] }

      before do
        File.write("test.html.erb", "<div><p>Hello</p></div>")
        File.write(".herb.yml", "formatter:\n  enabled: true\n")
      end

      it "exits with FORMAT_NEEDED without modifying the file" do
        expect(subject).to eq(described_class::EXIT_FORMAT_NEEDED)
        expect(File.read("test.html.erb")).to eq("<div><p>Hello</p></div>")
      end
    end

    context "with --check" do
      let(:argv) { ["--check", "test.html.erb"] }

      before { File.write(".herb.yml", "formatter:\n  enabled: true\n") }

      context "when file needs formatting" do
        before { File.write("test.html.erb", "<div><p>Hello</p></div>") }

        it "exits with FORMAT_NEEDED without modifying the file" do
          expect(subject).to eq(described_class::EXIT_FORMAT_NEEDED)
          expect(File.read("test.html.erb")).to eq("<div><p>Hello</p></div>")
          expect(stdout.string).to include("Checked")
        end
      end

      context "when file is already formatted" do
        before { File.write("test.html.erb", "<div>\n  <p>Hello</p>\n</div>") }

        it "exits successfully" do
          expect(subject).to eq(described_class::EXIT_SUCCESS)
        end
      end
    end

    context "with --force" do
      let(:argv) { ["--force", "test.html.erb"] }
      let(:original_content) { "<%# herb:formatter ignore %>\n<div><p>Hello</p></div>" }

      before do
        File.write("test.html.erb", original_content)
        File.write(".herb.yml", "formatter:\n  enabled: true\n")
      end

      it "formats files overriding ignore directives" do
        expect(subject).to eq(described_class::EXIT_SUCCESS)
        expect(File.read("test.html.erb")).to eq("<%# herb:formatter ignore %>\n\n<div>\n  <p>Hello</p>\n</div>")
      end
    end

    context "with --config-file" do
      let(:config_path) { File.join(Dir.pwd, "custom.herb.yml") }
      let(:argv) { ["--config-file", config_path, "test.html.erb"] }

      before do
        File.write("test.html.erb", "<div><p>Hello</p></div>")
        File.write(config_path, "formatter:\n  enabled: true\n")
      end

      it "loads configuration from the given path" do
        expect(subject).to eq(described_class::EXIT_SUCCESS)
      end
    end

    context "with --indent-width" do
      before do
        File.write("test.html.erb", "<div><p>Hello</p></div>")
        File.write(".herb.yml", "formatter:\n  enabled: true\n")
      end

      context "with a valid value" do
        let(:argv) { ["--indent-width", "4", "test.html.erb"] }

        it "formats with the specified indentation width" do
          expect(subject).to eq(described_class::EXIT_SUCCESS)
          expect(File.read("test.html.erb")).to eq("<div>\n    <p>Hello</p>\n</div>")
        end
      end

      context "with a non-integer value" do
        let(:argv) { ["--indent-width", "foo", "test.html.erb"] }

        it "exits with RUNTIME_ERROR and prints error to stderr" do
          expect(subject).to eq(described_class::EXIT_RUNTIME_ERROR)
          expect(stderr.string).to include("Invalid indent-width: foo. Must be a positive integer.")
        end
      end

      context "with zero" do
        let(:argv) { ["--indent-width", "0", "test.html.erb"] }

        it "exits with RUNTIME_ERROR" do
          expect(subject).to eq(described_class::EXIT_RUNTIME_ERROR)
          expect(stderr.string).to include("Invalid indent-width: 0. Must be a positive integer.")
        end
      end

      context "with a negative value" do
        let(:argv) { ["--indent-width", "-1", "test.html.erb"] }

        it "exits with RUNTIME_ERROR" do
          expect(subject).to eq(described_class::EXIT_RUNTIME_ERROR)
          expect(stderr.string).to include("Invalid indent-width: -1. Must be a positive integer.")
        end
      end
    end

    context "with --max-line-length" do
      before do
        File.write("test.html.erb", "<div><p>Hello</p></div>")
        File.write(".herb.yml", "formatter:\n  enabled: true\n")
      end

      context "with a valid value" do
        let(:argv) { ["--max-line-length", "100", "test.html.erb"] }

        it "accepts the value without error" do
          expect(subject).to eq(described_class::EXIT_SUCCESS)
        end
      end

      context "with a non-integer value" do
        let(:argv) { ["--max-line-length", "bad", "test.html.erb"] }

        it "exits with RUNTIME_ERROR and prints error to stderr" do
          expect(subject).to eq(described_class::EXIT_RUNTIME_ERROR)
          expect(stderr.string).to include("Invalid max-line-length: bad. Must be a positive integer.")
        end
      end

      context "with zero" do
        let(:argv) { ["--max-line-length", "0", "test.html.erb"] }

        it "exits with RUNTIME_ERROR" do
          expect(subject).to eq(described_class::EXIT_RUNTIME_ERROR)
          expect(stderr.string).to include("Invalid max-line-length: 0. Must be a positive integer.")
        end
      end
    end

    context "without special flags (format mode)" do
      let(:argv) { ["test.html.erb"] }

      before do
        File.write("test.html.erb", "<div><p>Hello</p></div>")
        File.write(".herb.yml", "formatter:\n  enabled: true\n")
      end

      it "formats the file in-place and exits successfully" do
        expect(subject).to eq(described_class::EXIT_SUCCESS)
        expect(File.read("test.html.erb")).to eq("<div>\n  <p>Hello</p>\n</div>")
        expect(stdout.string).to include("Formatted")
      end
    end
  end
end
