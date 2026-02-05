# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::NodeHelpers do
  # Create a test class that includes the module
  let(:helper_class) do
    Class.new do
      include Herb::Lint::Rules::NodeHelpers
    end
  end

  let(:helper) { helper_class.new }

  describe "#raw_tag_name" do
    context "when node is nil" do
      it "returns nil" do
        expect(helper.raw_tag_name(nil)).to be_nil
      end
    end

    context "when node has lowercase tag name" do
      let(:source) { "<div>content</div>" }
      let(:node) { Herb.parse(source, track_whitespace: true).value.children.first }

      it "returns the tag name in original case" do
        expect(helper.raw_tag_name(node)).to eq("div")
      end
    end

    context "when node has uppercase tag name" do
      let(:source) { "<DIV>content</DIV>" }
      let(:node) { Herb.parse(source, track_whitespace: true).value.children.first }

      it "returns the tag name in original case" do
        expect(helper.raw_tag_name(node)).to eq("DIV")
      end
    end
  end

  describe "#tag_name" do
    context "when node is nil" do
      it "returns nil" do
        expect(helper.tag_name(nil)).to be_nil
      end
    end

    context "when node has lowercase tag name" do
      let(:source) { "<div>content</div>" }
      let(:node) { Herb.parse(source, track_whitespace: true).value.children.first }

      it "returns the lowercase tag name" do
        expect(helper.tag_name(node)).to eq("div")
      end
    end

    context "when node has uppercase tag name" do
      let(:source) { "<DIV>content</DIV>" }
      let(:node) { Herb.parse(source, track_whitespace: true).value.children.first }

      it "returns the lowercase tag name" do
        expect(helper.tag_name(node)).to eq("div")
      end
    end
  end
end
