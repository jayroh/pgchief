# frozen_string_literal: true

module Pgchief
  module Prompt
    # Class to prompt for which database to restore
    class RestoreDatabase < Base
      def call
        database   = prompt.select("Which database needs restoring?", Pgchief::Database.all)
        local_file = prompt.select("Which backup file do you want to restore?", Pgchief::Database.backups_for(database))
        result     = Pgchief::Command::DatabaseRestore.call(database, local_file)

        prompt.say result

        return_to_main_menu
      end
    end
  end
end
