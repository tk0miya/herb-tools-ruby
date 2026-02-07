# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe Herb::Config::Loader do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:config_path) { File.join(tmp_dir, ".herb.yml") }

  after do
    FileUtils.remove_entry(tmp_dir)
  end

  describe ".load" do
    around do |example|
      Dir.chdir(tmp_dir) { example.run }
    end

    context "with validate: true (default)" do
      subject { described_class.load }

      context "when .herb.yml exists with valid YAML containing linter rules" do
        before do
          File.write(config_path, <<~YAML)
            linter:
              rules:
                alt-text:
                  severity: error
          YAML
        end

        it "merges user configuration with defaults" do
          expect(subject["linter"]["rules"]).to eq({ "alt-text" => { "severity" => "error" } })
          expect(subject["linter"]["include"]).to eq(["**/*.html.erb"])
          expect(subject["linter"]["exclude"]).to eq([])
        end
      end

      context "when .herb.yml exists with valid YAML overriding include patterns" do
        before do
          File.write(config_path, <<~YAML)
            linter:
              include:
                - "app/**/*.erb"
              exclude:
                - "vendor/**"
          YAML
        end

        it "uses user-specified patterns" do
          expect(subject["linter"]["include"]).to eq(["app/**/*.erb"])
          expect(subject["linter"]["exclude"]).to eq(["vendor/**"])
        end
      end

      context "when .herb.yml exists with empty content" do
        before do
          File.write(config_path, "")
        end

        it "returns defaults" do
          expect(subject).to eq(Herb::Config::Defaults.config)
        end
      end

      context "when .herb.yml does not exist" do
        it "returns default configuration" do
          expect(subject).to eq(Herb::Config::Defaults.config)
        end
      end

      context "when .herb.yml contains invalid YAML" do
        before do
          File.write(config_path, "invalid: yaml: content:")
        end

        it "raises Herb::Config::Error" do
          expect { subject }.to raise_error(Herb::Config::Error, /Invalid YAML/)
        end
      end

      context "when .herb.yml contains non-Hash root" do
        before do
          File.write(config_path, "- item1\n- item2")
        end

        it "raises Herb::Config::Error" do
          expect { subject }.to raise_error(Herb::Config::Error, /expected a Hash/)
        end
      end

      context "when configuration is invalid (schema validation)" do
        before do
          File.write(config_path, <<~YAML)
            linter:
              enabled: "yes"
              rules:
                alt-text:
                  severity: critical
          YAML
        end

        it "raises ValidationError" do
          expect { subject }.to raise_error(Herb::Config::ValidationError)
        end
      end
    end

    context "with validate: false" do
      subject { described_class.load(validate: false) }

      context "when configuration is invalid" do
        before do
          File.write(config_path, <<~YAML)
            linter:
              enabled: "yes"
              rules:
                alt-text:
                  severity: critical
          YAML
        end

        it "skips validation and loads configuration" do
          expect(subject["linter"]["enabled"]).to eq("yes")
        end
      end
    end
  end

  context "with path parameter" do
    subject { described_class.load(path:) }

    context "when file exists" do
      let(:path) { File.join(tmp_dir, "custom.yml") }

      before do
        File.write(path, <<~YAML)
          linter:
            rules:
              alt-text:
                severity: error
        YAML
      end

      it "loads configuration from specified path" do
        expect(subject["linter"]["rules"]).to eq({ "alt-text" => { "severity" => "error" } })
      end
    end

    context "when file does not exist" do
      let(:path) { File.join(tmp_dir, "nonexistent.yml") }

      it "raises Herb::Config::Error" do
        expect { subject }.to raise_error(Herb::Config::Error, /Configuration file not found/)
      end
    end
  end

  context "with HERB_CONFIG environment variable" do
    context "when points to existing file" do
      let(:env_config_path) { File.join(tmp_dir, "env-config.yml") }

      before do
        File.write(env_config_path, <<~YAML)
          linter:
            rules:
              alt-text:
                severity: warning
        YAML
        stub_const("ENV", ENV.to_h.merge("HERB_CONFIG" => env_config_path))
      end

      it "loads configuration from HERB_CONFIG path" do
        config = described_class.load
        expect(config["linter"]["rules"]).to eq({ "alt-text" => { "severity" => "warning" } })
      end
    end

    context "when points to nonexistent file" do
      before do
        stub_const("ENV", ENV.to_h.merge("HERB_CONFIG" => File.join(tmp_dir, "nonexistent.yml")))
      end

      it "raises Herb::Config::Error" do
        expect do
          described_class.load
        end.to raise_error(Herb::Config::Error, /Configuration file not found.*HERB_CONFIG/)
      end
    end
  end

  context "with HERB_NO_CONFIG environment variable" do
    before do
      stub_const("ENV", ENV.to_h.merge("HERB_NO_CONFIG" => "1"))
    end

    it "returns default configuration without searching for files" do
      # Create a config file that should be ignored
      File.write(config_path, <<~YAML)
        linter:
          rules:
            alt-text:
              severity: error
      YAML

      config = described_class.load
      expect(config).to eq(Herb::Config::Defaults.config)
      expect(config["linter"]["rules"]).to eq({})
    end
  end

  context "with upward directory traversal" do
    let(:nested_dir) { File.join(tmp_dir, "a", "b", "c") }

    around do |example|
      FileUtils.mkdir_p(nested_dir)
      Dir.chdir(nested_dir) { example.run }
    end

    context "when finds configuration in parent directory" do
      let(:parent_config_path) { File.join(tmp_dir, "a", ".herb.yml") }

      before do
        File.write(parent_config_path, <<~YAML)
          linter:
            rules:
              alt-text:
                severity: info
        YAML
      end

      it "loads configuration from parent directory" do
        config = described_class.load
        expect(config["linter"]["rules"]).to eq({ "alt-text" => { "severity" => "info" } })
      end
    end

    context "when multiple parent directories have configuration" do
      let(:parent_config_path) { File.join(tmp_dir, "a", ".herb.yml") }
      let(:root_config_path) { File.join(tmp_dir, ".herb.yml") }

      before do
        File.write(parent_config_path, <<~YAML)
          linter:
            rules:
              alt-text:
                severity: info
        YAML
        File.write(root_config_path, <<~YAML)
          linter:
            rules:
              alt-text:
                severity: hint
        YAML
      end

      it "uses the closest configuration file" do
        config = described_class.load
        expect(config["linter"]["rules"]).to eq({ "alt-text" => { "severity" => "info" } })
      end
    end

    context "when no configuration file is found" do
      it "returns default configuration" do
        config = described_class.load
        expect(config).to eq(Herb::Config::Defaults.config)
      end
    end
  end
end
