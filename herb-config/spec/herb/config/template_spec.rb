# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "yaml"

RSpec.describe Herb::Config::Template do
  describe ".default_config" do
    it "returns the default configuration template as a string" do
      result = described_class.default_config
      expect(result).to be_a(String)
      expect(result).to include("Herb Tools Configuration")
      expect(result).to include("linter:")
      expect(result).to include("formatter:")
    end

    it "returns valid YAML" do
      result = described_class.default_config
      expect { YAML.safe_load(result, permitted_classes: [Symbol]) }.not_to raise_error
    end

    it "includes linter configuration" do
      result = described_class.default_config
      config = YAML.safe_load(result, permitted_classes: [Symbol])
      expect(config).to have_key("linter")
      expect(config["linter"]).to have_key("enabled")
      expect(config["linter"]).to have_key("include")
      expect(config["linter"]).to have_key("exclude")
      expect(config["linter"]).to have_key("rules")
    end

    it "includes formatter configuration" do
      result = described_class.default_config
      config = YAML.safe_load(result, permitted_classes: [Symbol])
      expect(config).to have_key("formatter")
      expect(config["formatter"]).to have_key("enabled")
      expect(config["formatter"]).to have_key("indentWidth")
      expect(config["formatter"]).to have_key("maxLineLength")
    end
  end

  describe ".generate" do
    let(:temp_dir) { Dir.mktmpdir }

    after do
      FileUtils.remove_entry(temp_dir) if temp_dir && File.exist?(temp_dir)
    end

    context "when .herb.yml does not exist" do
      it "creates .herb.yml file" do
        described_class.generate(path: temp_dir)
        config_path = File.join(temp_dir, ".herb.yml")
        expect(File.exist?(config_path)).to be true
      end

      it "writes the default configuration template" do
        described_class.generate(path: temp_dir)
        config_path = File.join(temp_dir, ".herb.yml")
        content = File.read(config_path)
        expect(content).to eq(described_class.default_config)
      end

      it "creates valid YAML content" do
        described_class.generate(path: temp_dir)
        config_path = File.join(temp_dir, ".herb.yml")
        expect { YAML.safe_load_file(config_path, permitted_classes: [Symbol]) }.not_to raise_error
      end
    end

    context "when .herb.yml already exists" do
      before do
        config_path = File.join(temp_dir, ".herb.yml")
        File.write(config_path, "existing: config")
      end

      it "raises an error" do
        expect { described_class.generate(path: temp_dir) }
          .to raise_error(Herb::Config::Error, ".herb.yml already exists")
      end

      it "does not overwrite the existing file" do
        config_path = File.join(temp_dir, ".herb.yml")
        expect { described_class.generate(path: temp_dir) }.to raise_error(Herb::Config::Error)
        expect(File.read(config_path)).to eq("existing: config")
      end
    end

    context "when path parameter is not provided" do
      around do |example|
        Dir.chdir(temp_dir) do
          example.run
        end
      end

      it "creates .herb.yml in the current directory" do
        described_class.generate
        expect(File.exist?(".herb.yml")).to be true
      end
    end
  end
end
