# frozen_string_literal: true

module Pgchief
  module Prompt
    # Kicks off the CLI with an initial prompt
    class Start < Base
      def call
        manage_config!

        result = prompt.select(
          'Welcome! How can I help?',
          [
            'Database management',
            'User management'
          ]
        )

        klassify('prompt', result).call
      end

      private

      def manage_config!
        Pgchief::Config.load_config!(params.first)
        Pgchief::Config.set_up_file_structure!
      end
    end
  end
end
