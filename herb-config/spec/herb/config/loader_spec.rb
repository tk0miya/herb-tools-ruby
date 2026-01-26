# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe Herb::Config::Loader do
  describe "#load" do
    context "when .herb.yml exists in working directory" do
      it "loads and merges with defaults" do
        Dir.mktmpdir do |dir|
          config_path = File.join(dir, ".herb.yml")
          File.write(config_path, <<~YAML)
            linter:
              rules:
                alt-text: error
          YAML

          loader = described_class.new(working_dir: dir)
          config = loader.load

          expect(config["linter"]["include"]).to eq(["**/*.html.erb"])
          expect(config["linter"]["rules"]["alt-text"]).to eq("error")
        end
      end
    end

    context "when .herb.yml is absent" do
      it "returns default configuration" do
        Dir.mktmpdir do |dir|
          loader = described_class.new(working_dir: dir)
          config = loader.load

          expect(config).to eq(Herb::Config::Defaults.config)
        end
      end
    end

    context "when .herb.yml contains invalid YAML" do
      it "raises ParseError" do
        Dir.mktmpdir do |dir|
          config_path = File.join(dir, ".herb.yml")
          File.write(config_path, "invalid: yaml: content:")

          loader = described_class.new(working_dir: dir)

          expect { loader.load }.to raise_error(Herb::Config::ParseError, /Invalid YAML/)
        end
      end
    end

    context "when .herb.yml is empty" do
      it "returns default configuration" do
        Dir.mktmpdir do |dir|
          config_path = File.join(dir, ".herb.yml")
          File.write(config_path, "")

          loader = described_class.new(working_dir: dir)
          config = loader.load

          expect(config).to eq(Herb::Config::Defaults.config)
        end
      end
    end

    context "when .herb.yml contains non-hash content" do
      it "raises ParseError" do
        Dir.mktmpdir do |dir|
          config_path = File.join(dir, ".herb.yml")
          File.write(config_path, "- item1\n- item2")

          loader = described_class.new(working_dir: dir)

          expect { loader.load }.to raise_error(Herb::Config::ParseError, /expected a hash/)
        end
      end
    end

    context "when explicit path is provided" do
      it "loads from the specified path" do
        Dir.mktmpdir do |dir|
          config_path = File.join(dir, "custom-config.yml")
          File.write(config_path, <<~YAML)
            linter:
              include:
                - "custom/**/*.erb"
          YAML

          loader = described_class.new(path: config_path)
          config = loader.load

          expect(config["linter"]["include"]).to eq(["custom/**/*.erb"])
        end
      end

      it "raises FileNotFoundError when path does not exist" do
        loader = described_class.new(path: "/nonexistent/path/.herb.yml")

        expect { loader.load }.to raise_error(
          Herb::Config::FileNotFoundError,
          /Configuration file not found/
        )
      end
    end

    context "when HERB_CONFIG environment variable is set" do
      around do |example|
        original_value = ENV.fetch("HERB_CONFIG", nil)
        example.run
      ensure
        if original_value.nil?
          ENV.delete("HERB_CONFIG")
        else
          ENV["HERB_CONFIG"] = original_value
        end
      end

      it "loads from the environment variable path" do
        Dir.mktmpdir do |dir|
          config_path = File.join(dir, "env-config.yml")
          File.write(config_path, <<~YAML)
            linter:
              rules:
                attribute-quotes: warn
          YAML

          ENV["HERB_CONFIG"] = config_path

          loader = described_class.new(working_dir: "/some/other/dir")
          config = loader.load

          expect(config["linter"]["rules"]["attribute-quotes"]).to eq("warn")
        end
      end

      it "raises FileNotFoundError when environment path does not exist" do
        ENV["HERB_CONFIG"] = "/nonexistent/env/path.yml"

        loader = described_class.new

        expect { loader.load }.to raise_error(
          Herb::Config::FileNotFoundError,
          /Configuration file not found/
        )
      end
    end
  end

  describe "#find_config_path" do
    context "when .herb.yml exists in parent directory" do
      it "finds the config file by searching upward" do
        Dir.mktmpdir do |dir|
          config_path = File.join(dir, ".herb.yml")
          File.write(config_path, "linter: {}")

          subdir = File.join(dir, "app", "views")
          FileUtils.mkdir_p(subdir)

          loader = described_class.new(working_dir: subdir)

          expect(loader.find_config_path).to eq(config_path)
        end
      end
    end

    context "when no config file exists" do
      it "returns nil" do
        Dir.mktmpdir do |dir|
          loader = described_class.new(working_dir: dir)

          expect(loader.find_config_path).to be_nil
        end
      end
    end

    context "when explicit path is provided and exists" do
      it "returns the explicit path" do
        Dir.mktmpdir do |dir|
          config_path = File.join(dir, "my-config.yml")
          File.write(config_path, "linter: {}")

          loader = described_class.new(path: config_path)

          expect(loader.find_config_path).to eq(config_path)
        end
      end
    end

    context "when explicit path is provided but does not exist" do
      it "raises FileNotFoundError" do
        loader = described_class.new(path: "/nonexistent/config.yml")

        expect { loader.find_config_path }.to raise_error(
          Herb::Config::FileNotFoundError
        )
      end
    end
  end
end
