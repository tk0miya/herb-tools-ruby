# frozen_string_literal: true

# Load order follows dependency graph (each file can only depend on files already loaded):
require_relative "highlight/version"
require_relative "highlight/color"               # no deps within gem
require_relative "highlight/themes"              # no deps within gem
require_relative "highlight/syntax_renderer"     # depends on: Color, Themes
require_relative "highlight/diagnostic_renderer" # depends on: Color, SyntaxRenderer

module Herb
  module Highlight
    class Error < StandardError; end
  end
end
