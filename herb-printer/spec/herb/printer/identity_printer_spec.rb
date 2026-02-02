# frozen_string_literal: true

RSpec.describe Herb::Printer::IdentityPrinter do
  describe ".print" do
    subject { described_class.print(parse_result) }

    let(:parse_result) { Herb.parse(source, track_whitespace: true) }

    context "when input is plain text" do
      let(:source) { "Hello, world!" }

      it { is_expected.to eq(source) }
    end

    context "when input is whitespace only" do
      let(:source) { "  \n  " }

      it { is_expected.to eq(source) }
    end

    context "when input is a simple element" do
      let(:source) { "<div></div>" }

      it { is_expected.to eq(source) }
    end

    context "when input is an element with text content" do
      let(:source) { "<div>Hello</div>" }

      it { is_expected.to eq(source) }
    end

    context "when open tag contains trailing space" do
      let(:source) { "<div >text</div>" }

      it { is_expected.to eq(source) }
    end

    context "when close tag contains spaces" do
      let(:source) { "<div></ div >" }

      it { is_expected.to eq(source) }
    end

    context "when input is a void element" do
      let(:source) { "<br>" }

      it { is_expected.to eq(source) }
    end

    context "when input is a void element with attribute" do
      let(:source) { '<img src="photo.jpg">' }

      it { is_expected.to eq(source) }
    end

    context "when input has a double-quoted attribute" do
      let(:source) { '<div class="container">text</div>' }

      it { is_expected.to eq(source) }
    end

    context "when input has a single-quoted attribute" do
      let(:source) { "<div class='single-quoted'>text</div>" }

      it { is_expected.to eq(source) }
    end

    context "when input has a boolean attribute" do
      let(:source) { '<input type="text" disabled>' }

      it { is_expected.to eq(source) }
    end

    context "when input has multiple attributes" do
      let(:source) { '<div id="main" class="wrapper" data-value="123">text</div>' }

      it { is_expected.to eq(source) }
    end

    context "when attribute has spaces around equals" do
      let(:source) { '<div class = "spaced">text</div>' }

      it { is_expected.to eq(source) }
    end

    context "when input is an HTML comment" do
      let(:source) { "<!-- comment -->" }

      it { is_expected.to eq(source) }
    end

    context "when input is a multiline HTML comment" do
      let(:source) { "<!-- multi\nline\ncomment -->" }

      it { is_expected.to eq(source) }
    end

    context "when input is a DOCTYPE" do
      let(:source) { "<!DOCTYPE html>" }

      it { is_expected.to eq(source) }
    end

    context "when input is an ERB output tag" do
      let(:source) { "<%= user.name %>" }

      it { is_expected.to eq(source) }
    end

    context "when input is an ERB comment tag" do
      let(:source) { "<%# comment %>" }

      it { is_expected.to eq(source) }
    end

    context "when input is an ERB yield tag" do
      let(:source) { "<%= yield %>" }

      it { is_expected.to eq(source) }
    end

    context "when input is an ERB tag with trim markers" do
      let(:source) { "<%- trimmed -%>" }

      it { is_expected.to eq(source) }
    end

    context "when input is an ERB block with each" do
      let(:source) { "<% items.each do |item| %><li><%= item %></li><% end %>" }

      it { is_expected.to eq(source) }
    end

    context "when input is a simple ERB if" do
      let(:source) { "<% if condition %>yes<% end %>" }

      it { is_expected.to eq(source) }
    end

    context "when input is an ERB if/else" do
      let(:source) { "<% if condition %>yes<% else %>no<% end %>" }

      it { is_expected.to eq(source) }
    end

    context "when input is an ERB unless" do
      let(:source) { "<% unless done %>work<% end %>" }

      it { is_expected.to eq(source) }
    end

    context "when input is an ERB unless/else" do
      let(:source) { "<% unless done %>work<% else %>rest<% end %>" }

      it { is_expected.to eq(source) }
    end

    context "when input is a nested ERB if/elsif/else" do
      let(:source) { "<% if x == 1 %>one<% elsif x == 2 %>two<% else %>other<% end %>" }

      it { is_expected.to eq(source) }
    end

    context "when input is an ERB while loop" do
      let(:source) { "<% while running %><%= status %><% end %>" }

      it { is_expected.to eq(source) }
    end

    context "when input is an ERB until loop" do
      let(:source) { "<% until done %><%= progress %><% end %>" }

      it { is_expected.to eq(source) }
    end

    context "when input is an ERB for loop" do
      let(:source) { "<% for item in list %><%= item %><% end %>" }

      it { is_expected.to eq(source) }
    end

    context "when input is an ERB case/when" do
      let(:source) { "<% case x %><% when 1 %>one<% when 2 %>two<% else %>other<% end %>" }

      it { is_expected.to eq(source) }
    end

    context "when input is an ERB case/in (pattern matching)" do
      let(:source) { "<% case x %><% in 1 %>one<% in 2 %>two<% else %>other<% end %>" }

      it { is_expected.to eq(source) }
    end

    context "when input is an ERB begin/rescue" do
      let(:source) { "<% begin %><%= risky %><% rescue %><%= fallback %><% end %>" }

      it { is_expected.to eq(source) }
    end

    context "when input is an ERB begin/rescue/ensure" do
      let(:source) { "<% begin %><%= x %><% rescue => e %><%= e %><% ensure %><%= cleanup %><% end %>" }

      it { is_expected.to eq(source) }
    end

    context "when input is an ERB begin with chained rescue" do
      let(:source) do
        "<% begin %><%= x %><% rescue ArgumentError %><%= a %>" \
          "<% rescue StandardError %><%= b %><% end %>"
      end

      it { is_expected.to eq(source) }
    end

    context "when input is a mixed HTML and ERB template" do
      let(:source) do
        <<~ERB.chomp
          <div class="container">
            <% if logged_in? %>
              <h1>Welcome</h1>
              <% begin %>
                <%= render_profile %>
              <% rescue => e %>
                <p>Error: <%= e.message %></p>
              <% end %>
            <% else %>
              <p>Please log in</p>
            <% end %>
          </div>
        ERB
      end

      it { is_expected.to eq(source) }
    end
  end
end
