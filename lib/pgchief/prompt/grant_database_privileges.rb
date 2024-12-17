# frozen_string_literal: true

module Pgchief
  module Prompt
    # Class to ask for database names, in order to create it
    class GrantDatabasePrivileges < Base
      def call
        username  = params[0] || select_user
        password  = params[1] || ask_for_password
        databases = params[2] || prompt.multi_select("Give \"#{username}\" access to database(s):",
                                                     Pgchief::Database.all)

        result = Pgchief::Command::DatabasePrivilegesGrant.call(username, password, databases)
        prompt.say result

        return_to_main_menu
      end

      def select_user
        prompt.select("Select user to update:", Pgchief::User.all)
      end

      def ask_for_password
        prompt.mask("Password:")
      end
    end
  end
end
