# frozen_string_literal: true

module Pgchief
  module Prompt
    # Class to ask for database names, in order to create it
    class GrantDatabasePrivileges < Base
      def call
        username  = params.first
        databases = prompt.select(
          "Select database:",
          Pgchief::Database.all,
          multiselect: true
        )

        Pgchief::Command::GrantDatabasePrivileges.call(username, databases)
      end
    end
  end
end
