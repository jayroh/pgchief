# frozen_string_literal: true

module Pgchief
  module Prompt
    # Class to prompt for which database to drop
    class DropDatabase < Base
      def call
        database = prompt.select("Which database needs to be dropped?", Pgchief::Database.all)
        result   = Pgchief::Command::DatabaseDrop.call(database)

        prompt.say result

        return_to_main_menu
      end
    end
  end
end
