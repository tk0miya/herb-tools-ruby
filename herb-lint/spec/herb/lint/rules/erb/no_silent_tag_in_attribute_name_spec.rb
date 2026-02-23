# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Erb::NoSilentTagInAttributeName do
  describe ".rule_name" do
    it "returns 'erb-no-silent-tag-in-attribute-name'" do
      expect(described_class.rule_name).to eq("erb-no-silent-tag-in-attribute-name")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow ERB silent tags within HTML attribute names")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    subject { described_class.new(matcher:).check(document, context) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    # Good examples from documentation
    context "when attribute name contains output tag" do
      let(:source) { '<div data-<%= key %>-target="value"></div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when output tag outputs entire attributes" do
      let(:source) { "<div <%= data_attributes_for(user) %>></div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "when attribute name contains standard silent tag" do
      let(:source) { '<div data-<% key %>-id="value"></div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-silent-tag-in-attribute-name")
        expect(subject.first.message).to include("Remove silent ERB tag from HTML attribute name")
        expect(subject.first.message).to include("(<%)")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when attribute name contains comment tag" do
      let(:source) { '<div data-<%# key %>-id="thing"></div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-silent-tag-in-attribute-name")
        expect(subject.first.message).to include("(<%#)")
      end
    end

    context "when attribute name contains silent tag with trim" do
      let(:source) { '<div data-<%- key -%>-id="thing"></div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-silent-tag-in-attribute-name")
        expect(subject.first.message).to include("(<%-)")
      end
    end

    context "when silent tag is used for conditional attributes" do
      let(:source) { '<div <% if valid? %>data-valid="true"<% else %>data-valid="false"<% end %>></div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when silent tag is used for conditional class attribute" do
      let(:source) { '<span <% if user.admin? %>class="admin"<% end %>></span>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element has static attributes" do
      let(:source) { '<div class="container" id="main"></div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiple attributes have silent tags in names" do
      let(:source) do
        '<div data-<% key1 %>-first="1" data-<% key2 %>-second="2"></div>'
      end

      it "reports an offense for each attribute" do
        expect(subject.size).to eq(2)
        expect(subject.all? { _1.rule_name == "erb-no-silent-tag-in-attribute-name" }).to be true
      end
    end

    context "when attribute value contains silent tag" do
      let(:source) { '<div data-target="<% value %>"></div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when attribute has both silent tag in name and value" do
      let(:source) { '<div data-<% key %>-target="<% value %>"></div>' }

      it "reports offense only for the name" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Remove silent ERB tag from HTML attribute name")
      end
    end

    context "when mixed with valid and invalid attributes" do
      let(:source) do
        '<div class="static" data-<% key %>-target="value" id="main"></div>'
      end

      it "reports offense only for the invalid attribute" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-silent-tag-in-attribute-name")
      end
    end

    context "when element has no attributes" do
      let(:source) { "<div></div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when self-closing element has silent tag in attribute name" do
      let(:source) { '<input data-<% field %>-name="test" />' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-silent-tag-in-attribute-name")
      end
    end

    context "when attribute name is at end of attribute" do
      let(:source) { '<div data-target-<% suffix %>="value"></div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end
  end
end
