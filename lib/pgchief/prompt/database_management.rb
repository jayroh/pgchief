# frozen_string_literal: true

module Pgchief
  module Prompt
    # Class to manage database operations
    class DatabaseManagement < Base
      def call
        prompt = TTY::Prompt.new
        result = prompt.select("Database management", [
                                 "Create database",
                                 "Drop database",
                                 "Database List",
                                 "Backup database",
                                 "Restore database"
                               ])
        scope = result == "Database List" ? "command" : "prompt"

        klassify(scope, result).call
      end
    end
  end
end
