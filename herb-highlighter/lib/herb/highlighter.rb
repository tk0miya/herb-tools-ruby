# frozen_string_literal: true

require_relative "highlighter/color"
require_relative "highlighter/diagnostic_renderer"
require_relative "highlighter/file_renderer"
require_relative "highlighter/syntax_renderer"
require_relative "highlighter/themes"
require_relative "highlighter/version"
require_relative "highlighter/highlighter"

module Herb
  module Highlighter
    class Error < StandardError; end
  end
end
