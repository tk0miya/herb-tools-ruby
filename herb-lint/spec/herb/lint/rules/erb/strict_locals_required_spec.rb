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
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    subject { described_class.new(matcher:).check(document, context) }

    let(:matcher) { build(:pattern_matcher) }
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

      # Good examples from documentation
      context "when partial has required keyword argument" do
        let(:source) do
          <<~ERB
            <%# locals: (user:) %>

            <div class="user-card">
              <%= user.name %>
            </div>
          ERB
        end

        it "does not report an offense" do
          expect(subject).to be_empty
        end
      end

      context "when partial has keyword argument and default" do
        let(:source) do
          <<~ERB
            <%# locals: (user:, admin: false) %>

            <div class="user-card">
              <%= user.name %>

              <% if admin %>
              <span class="badge">Admin</span>
              <% end %>
            </div>
          ERB
        end

        it "does not report an offense" do
          expect(subject).to be_empty
        end
      end

      context "when partial has no locals (empty declaration)" do
        let(:source) do
          <<~ERB
            <%# locals: () %>

            <p>Static content only</p>
          ERB
        end

        it "does not report an offense" do
          expect(subject).to be_empty
        end
      end

      # Bad examples from documentation
      context "when partial is without strict locals declaration" do
        let(:source) do
          <<~ERB
            <div class="user-card">
              <%= user.name %>
            </div>
          ERB
        end

        it "reports an offense" do
          expected_message = "Partial is missing a strict locals declaration. " \
                             "Add `<%# locals: (...) %>` at the top of the file."
          expect(subject.size).to eq(1)
          expect(subject.first.rule_name).to eq("erb-strict-locals-required")
          expect(subject.first.message).to eq(expected_message)
          expect(subject.first.severity).to eq("error")
        end
      end

      # Additional edge case tests
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
