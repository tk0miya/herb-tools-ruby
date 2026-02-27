# frozen_string_literal: true

# Require files in ASCII order
require_relative "highlight/color"
require_relative "highlight/diagnostic_renderer"
require_relative "highlight/syntax_renderer"
require_relative "highlight/themes"
require_relative "highlight/version"

module Herb
  module Highlight
    class Error < StandardError; end
  end
end
