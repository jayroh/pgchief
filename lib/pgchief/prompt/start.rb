# frozen_string_literal: true

module Pgchief
  module Prompt
    # Kicks off the CLI with an initial prompt
    class Start < Base
      def call
        result = prompt.select(
          "Welcome! How can I help?",
          [
            "Database management",
            "User management"
          ]
        )

        klassify("prompt", result).call
      end
    end
  end
end
