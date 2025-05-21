# frozen_string_literal: true

module Pgchief
  module Command
    # Command object to quickly restore the latest backup for a database
    class QuickBackup < Base
      def call
        database = params.last
        Pgchief::Config.load_config!(params.first)
        Pgchief::Config.set_up_file_structure!
        Pgchief::Command::DatabaseBackup.call(database)
      end
    end
  end
end
