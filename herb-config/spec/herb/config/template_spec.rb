# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "yaml"

RSpec.describe Herb::Config::Template do
  describe ".generate" do
    let(:temp_dir) { Dir.mktmpdir }

    after do
      FileUtils.remove_entry(temp_dir) if temp_dir && File.exist?(temp_dir)
    end

    context "when .herb.yml does not exist" do
      subject(:generate) { described_class.generate(base_dir: temp_dir) }

      it "creates .herb.yml file with valid YAML content" do
        generate
        config_path = File.join(temp_dir, ".herb.yml")
        expect(File.exist?(config_path)).to be true
        expect { YAML.safe_load_file(config_path, permitted_classes: [Symbol]) }.not_to raise_error
      end
    end

    context "when .herb.yml already exists" do
      subject(:generate) { described_class.generate(base_dir: temp_dir) }

      before do
        config_path = File.join(temp_dir, ".herb.yml")
        File.write(config_path, "existing: config")
      end

      it "raises an error without overwriting the file" do
        config_path = File.join(temp_dir, ".herb.yml")
        expect { generate }.to raise_error(Herb::Config::Error, ".herb.yml already exists")
        expect(File.read(config_path)).to eq("existing: config")
      end
    end
  end
end
