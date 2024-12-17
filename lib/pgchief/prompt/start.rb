# frozen_string_literal: true

module Pgchief
  module Prompt
    # Kicks off the CLI with an initial prompt
    class Start < Base
      def call
        prompt_message = params.first || "Welcome! How can I help?"
        manage_config!

        result = prompt.select(
          prompt_message,
          [
            "Database management",
            "User management",
            "Quit"
          ]
        )

        klassify("prompt", result).call
      end

      private

      def manage_config!
        Pgchief::Config.load_config!
        Pgchief::Config.set_up_file_structure!
      end
    end
  end
end
