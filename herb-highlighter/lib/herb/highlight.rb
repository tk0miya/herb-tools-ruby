# frozen_string_literal: true

require_relative "highlight/color"
require_relative "highlight/diagnostic_renderer"
require_relative "highlight/file_renderer"
require_relative "highlight/syntax_renderer"
require_relative "highlight/themes"
require_relative "highlight/version"
require_relative "highlight/highlighter"

module Herb
  module Highlight
    class Error < StandardError; end
  end
end
