# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Erb::StrictLocalsRequired do
  describe ".rule_name" do
    it "returns 'erb-strict-locals-required'" do
      expect(described_class.rule_name).to eq("erb-strict-locals-required")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Require strict_locals magic comment in partial files")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    subject { described_class.new.check(document, context) }

    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context, file_path:) }

    context "when file is not a partial" do
      let(:file_path) { "/path/to/file.html.erb" }

      context "when it has no strict_locals comment" do
        let(:source) { "<div><%= name %></div>" }

        it "does not report an offense" do
          expect(subject).to be_empty
        end
      end

      context "when it has strict_locals comment" do
        let(:source) do
          <<~ERB
            <%# locals: (name: String) %>
            <div><%= name %></div>
          ERB
        end

        it "does not report an offense" do
          expect(subject).to be_empty
        end
      end
    end

    context "when file is a partial (starts with underscore)" do
      let(:file_path) { "/path/to/_partial.html.erb" }

      context "when it has valid strict_locals comment" do
        let(:source) do
          <<~ERB
            <%# locals: (name: String) %>
            <div><%= name %></div>
          ERB
        end

        it "does not report an offense" do
          expect(subject).to be_empty
        end
      end

      context "when it has strict_locals comment with extra whitespace" do
        let(:source) do
          <<~ERB
            <%# locals:  (name: String) %>
            <div><%= name %></div>
          ERB
        end

        it "does not report an offense" do
          expect(subject).to be_empty
        end
      end

      context "when it has strict_locals comment without spaces" do
        let(:source) do
          <<~ERB
            <%# locals:(name: String) %>
            <div><%= name %></div>
          ERB
        end

        it "does not report an offense" do
          expect(subject).to be_empty
        end
      end

      context "when it has no strict_locals comment" do
        let(:source) { "<div><%= name %></div>" }

        it "reports an offense" do
          expected_message = "Partial files must have a strict_locals magic comment (<%# locals: ... %>)"
          expect(subject.size).to eq(1)
          expect(subject.first.rule_name).to eq("erb-strict-locals-required")
          expect(subject.first.message).to eq(expected_message)
          expect(subject.first.severity).to eq("warning")
        end
      end

      context "when it has only a regular comment" do
        let(:source) do
          <<~ERB
            <%# This is a regular comment %>
            <div><%= name %></div>
          ERB
        end

        it "reports an offense" do
          expect(subject.size).to eq(1)
          expect(subject.first.rule_name).to eq("erb-strict-locals-required")
        end
      end

      context "when it has empty strict_locals declaration" do
        let(:source) do
          <<~ERB
            <%# locals: () %>
            <div>Static content</div>
          ERB
        end

        it "does not report an offense" do
          expect(subject).to be_empty
        end
      end

      context "when strict_locals comment is not first" do
        let(:source) do
          <<~ERB
            <div>Content</div>
            <%# locals: (name: String) %>
            <div><%= name %></div>
          ERB
        end

        it "does not report an offense" do
          expect(subject).to be_empty
        end
      end

      context "when it has multiple comments including strict_locals" do
        let(:source) do
          <<~ERB
            <%# This is a regular comment %>
            <%# locals: (name: String) %>
            <div><%= name %></div>
          ERB
        end

        it "does not report an offense" do
          expect(subject).to be_empty
        end
      end
    end
  end
end
