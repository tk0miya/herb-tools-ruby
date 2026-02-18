# frozen_string_literal: true

module Herb
  module Config
    # Provides default configuration template for --init command
    module Template
      # Default .herb.yml configuration template
      DEFAULT_TEMPLATE = <<~YAML
        # Herb Tools Configuration
        # https://github.com/marcoroth/herb

        linter:
          enabled: true
          include:
            - "**/*.html.erb"
            - "**/*.turbo_stream.erb"
          exclude:
            - "vendor/**"
            - "node_modules/**"
          rules:
            # Uncomment to customize rules
            # html-attribute-quotes:
            #   severity: error
            # html-img-require-alt:
            #   severity: warning
            # html-no-positive-tabindex:
            #   enabled: false

        formatter:
          enabled: true
          indentWidth: 2
          maxLineLength: 80
          include:
            - "**/*.html.erb"
            - "**/*.turbo_stream.erb"
          exclude:
            - "vendor/**"
            - "node_modules/**"
          rewriter:
            pre: []
            post: []
      YAML

      # Generates a .herb.yml file in the specified directory
      # @rbs base_dir: String
      def self.generate(base_dir:) #: void
        config_path = File.join(base_dir, ".herb.yml")

        raise Error, ".herb.yml already exists" if File.exist?(config_path)

        File.write(config_path, DEFAULT_TEMPLATE)
      end
    end
  end
end
