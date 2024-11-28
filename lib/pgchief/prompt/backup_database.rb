# frozen_string_literal: true

module Pgchief
  module Prompt
    # Class to prompt for which database to backup
    class BackupDatabase < Base
      def call
        database = prompt.select("Which database needs backing up?", Pgchief::Database.all)
        result   = Pgchief::Command::DatabaseBackup.call(database)

        prompt.say result
      end
    end
  end
end
