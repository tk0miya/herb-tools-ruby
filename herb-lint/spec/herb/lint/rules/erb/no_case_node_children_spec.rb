# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Erb::NoCaseNodeChildren do
  describe ".rule_name" do
    it "returns 'erb-no-case-node-children'" do
      expect(described_class.rule_name).to eq("erb-no-case-node-children")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow direct children inside case ERB blocks")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    subject { described_class.new.check(document, context) }

    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    # Good example from documentation
    context "when case has no direct children" do
      let(:source) do
        <<~ERB
          <% case variable %>
          <% when "a" %>
            A
          <% when "b" %>
            B
          <% else %>
            C
          <% end %>
        ERB
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad example from documentation
    context "when case has direct text content between case and when" do
      let(:source) do
        <<~ERB
          <% case variable %>
            This content is outside of any when/in/else block!
          <% when "a" %>
            A
          <% when "b" %>
            B
          <% else %>
            C
          <% end %>
        ERB
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-case-node-children")
        expect(subject.first.message).to eq("Content exists outside of any rendered when/in/else branches")
        expect(subject.first.severity).to eq("error")
      end
    end

    # Additional test cases
    context "when case has direct HTML element children" do
      let(:source) do
        <<~ERB
          <% case value %>
            <p>Direct content</p>
          <% when :a %>
            <p>A</p>
          <% end %>
        ERB
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-case-node-children")
        expect(subject.first.message).to eq("Content exists outside of any rendered when/in/else branches")
      end
    end

    context "when case has direct ERB output tag" do
      let(:source) do
        <<~ERB
          <% case value %>
            <%= some_value %>
          <% when :a %>
            <p>A</p>
          <% end %>
        ERB
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-case-node-children")
      end
    end

    context "when case has only whitespace between tags" do
      let(:source) { "<% case value %>\n  \n<% when :a %>\n  <p>A</p>\n<% end %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when case has HTML comment between case and when" do
      let(:source) do
        <<~ERB
          <% case value %>
            <!-- This is a comment -->
          <% when :a %>
            <p>A</p>
          <% end %>
        ERB
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when case has empty children array" do
      let(:source) { "<% case value %><% when :a %>\n<p>A</p>\n<% end %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when nested case has direct children but parent does not" do
      let(:source) do
        <<~ERB
          <% case outer %>
          <% when :a %>
            <% case inner %>
              <p>Direct nested content</p>
            <% when :x %>
              <p>X</p>
            <% end %>
          <% end %>
        ERB
      end

      it "reports an offense for the nested case only" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-case-node-children")
      end
    end

    context "when multiple case blocks have direct children" do
      let(:source) do
        <<~ERB
          <% case first %>
            <p>First direct</p>
          <% when :a %>
            <p>A</p>
          <% end %>
          <% case second %>
            <p>Second direct</p>
          <% when :b %>
            <p>B</p>
          <% end %>
        ERB
      end

      it "reports an offense for each case" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("erb-no-case-node-children"))
      end
    end

    context "when case-match (pattern matching) has no direct children" do
      let(:source) do
        <<~ERB
          <% case value %>
          <% in :a %>
            <p>A</p>
          <% in :b %>
            <p>B</p>
          <% end %>
        ERB
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when case-match (pattern matching) has direct children" do
      let(:source) do
        <<~ERB
          <% case value %>
            <p>Direct content</p>
          <% in :a %>
            <p>A</p>
          <% end %>
        ERB
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-case-node-children")
        expect(subject.first.message).to eq("Content exists outside of any rendered when/in/else branches")
      end
    end
  end
end
