# frozen_string_literal: true

module Herb
  module Config
    class Error < StandardError; end
  end
end

# Require files in ASCII order
require_relative "config/defaults"
require_relative "config/linter_config"
require_relative "config/loader"
require_relative "config/version"
