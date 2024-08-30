# frozen_string_literal: true

module Pgchief
  module Prompt
    # Class to ask for database name, in order to create it
    class CreateDatabase < Base
      def self.call
        prompt   = TTY::Prompt.new
        database = prompt.ask("Database name:")
        result   = Pgchief::Command::DatabaseCreate.call(database)

        prompt.say result
      end
    end
  end
end
