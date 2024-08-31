# frozen_string_literal: true

module Pgchief
  module Prompt
    # Class to ask for database names, in order to create it
    class GrantDatabasePrivileges < Base
      def call
        username  = params.first || select_user
        databases = prompt.multi_select("Give \"#{username}\" access to database(s):", Pgchief::Database.all)
        result    = Pgchief::Command::DatabasePrivilegesGrant.call(username, databases)

        prompt.say result
      end

      def select_user
        prompt.select("Select user to update:", Pgchief::User.all)
      end
    end
  end
end
