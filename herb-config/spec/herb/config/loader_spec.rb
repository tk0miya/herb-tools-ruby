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
    subject { described_class.load(dir: tmp_dir) }

    context "when .herb.yml exists with valid YAML containing linter rules" do
      before do
        File.write(config_path, <<~YAML)
          linter:
            rules:
              alt-text: error
        YAML
      end

      it "merges user configuration with defaults" do
        expect(subject["linter"]["rules"]).to eq({ "alt-text" => "error" })
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
  end
end
