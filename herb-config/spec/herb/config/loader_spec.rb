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
    context "with validate: true (default)" do
      subject { described_class.load(dir: tmp_dir) }

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
      subject { described_class.load(dir: tmp_dir, validate: false) }

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
end
