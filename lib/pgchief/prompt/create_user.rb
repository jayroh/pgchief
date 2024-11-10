# frozen_string_literal: true

module Pgchief
  module Prompt
    # Class to prompt for user creation details
    class CreateUser < Base
      def call
        username = prompt.ask("Username:")
        password = prompt.mask("Password:")
        result   = Pgchief::Command::UserCreate.call(username, password)

        prompt.say result

        yes_or_no(
          "Give \"#{username}\" access to database(s)?",
          yes: -> { Pgchief::Prompt::GrantDatabasePrivileges.call(username, password) }
        )
      end
    end
  end
end
