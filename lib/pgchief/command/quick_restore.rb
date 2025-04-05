# frozen_string_literal: true

module Pgchief
  module Command
    # Command object to quickly restore the latest backup for a database
    class QuickRestore < Base
      def call
        database = params.last
        Pgchief::Config.load_config!(params.first)
        Pgchief::Config.set_up_file_structure!

        filename = Pgchief::Database
                   .backups_for(database, remote: Pgchief::Config.remote_restore)
                   .first

        Pgchief::Command::DatabaseRestore.call(database, filename)
      end
    end
  end
end
