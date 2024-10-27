# frozen_string_literal: true

module Pgchief
  module Prompt
    # Kicks off the CLI with an initial prompt
    class Start < Base
      def call
        manage_config!

        result = prompt.select(
          "Welcome! How can I help?",
          [
            "Database management",
            "User management"
          ]
        )

        klassify("prompt", result).call
      end

      private

      def manage_config!
        Pgchief::Config.load_config!
        Pgchief::Config.set_up_file_structure!

        return unless Pgchief::Config.credentials_file

        Pgchief::Config.credentials_secret = prompt.mask("Enter credentials secret:")
      end
    end
  end
end
