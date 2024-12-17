# frozen_string_literal: true

module Pgchief
  module Prompt
    # Class to ask for database name, in order to create it
    class CreateDatabase < Base
      def call
        database = prompt.ask("Database name:")
        result   = Pgchief::Command::DatabaseCreate.call(database)

        prompt.say result

        return_to_main_menu
      end
    end
  end
end
