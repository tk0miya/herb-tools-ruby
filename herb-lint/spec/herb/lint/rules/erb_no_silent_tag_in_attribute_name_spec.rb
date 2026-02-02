# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::ErbNoSilentTagInAttributeName do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template, track_whitespace: true) }
  let(:context) { build(:context) }

  describe ".rule_name" do
    it "returns 'erb-no-silent-tag-in-attribute-name'" do
      expect(described_class.rule_name).to eq("erb-no-silent-tag-in-attribute-name")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow ERB silent tags inside HTML attribute names")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    context "when attribute has no ERB tags" do
      let(:template) { '<div class="active">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when attribute value contains an output tag" do
      let(:template) { '<div class="<%= active? ? \'active\' : \'\' %>">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when entire attribute is in an output tag" do
      let(:template) { '<div <%= active? ? \'class="active"\' : \'\' %>>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when tag contains an ERB comment" do
      let(:template) { '<div <%# comment %>class="active">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when if block conditionally adds attribute" do
      let(:template) { '<div <% if active? %>class="active"<% end %>>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-silent-tag-in-attribute-name")
        expect(subject.first.message).to eq("Use output tags or ternary expressions for conditional attributes")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when unless block conditionally adds attribute" do
      let(:template) { '<div <% unless disabled? %>class="enabled"<% end %>>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-silent-tag-in-attribute-name")
      end
    end

    context "when if block contains multiple attributes" do
      let(:template) { '<div <% if active? %>class="active" data-status="on"<% end %>>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-silent-tag-in-attribute-name")
      end
    end

    context "when multiple if blocks exist in the same tag" do
      let(:template) { '<div <% if a? %>class="a"<% end %> <% if b? %>id="b"<% end %>>' }

      it "reports an offense for each block" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("erb-no-silent-tag-in-attribute-name"))
      end
    end

    context "when silent tag contains non-attribute content" do
      let(:template) { "<div><% if true %>content<% end %></div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when if-elsif-else block adds attributes" do
      let(:template) do
        <<~ERB
          <div <% if a? %>
            class="a"
          <% elsif b? %>
            class="b"
          <% else %>
            class="default"
          <% end %>>
        ERB
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-silent-tag-in-attribute-name")
      end
    end

    context "when nested if blocks add attributes" do
      let(:template) { '<div <% if outer? %><% if inner? %>class="nested"<% end %><% end %>>' }

      it "reports an offense for the innermost block containing attributes" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-silent-tag-in-attribute-name")
      end
    end

    context "when case block conditionally adds attribute" do
      let(:template) do
        <<~ERB
          <div <% case status %>
          <% when :active %>
            class="active"
          <% when :inactive %>
            class="inactive"
          <% end %>>
        ERB
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-silent-tag-in-attribute-name")
      end
    end

    context "when for loop adds attributes" do
      let(:template) { '<div <% for i in [1,2] %>data-index="<%= i %>"<% end %>>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-silent-tag-in-attribute-name")
      end
    end
  end
end
