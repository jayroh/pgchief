# frozen_string_literal: true

module Pgchief
  module Prompt
    # Class to show all users
    class ListUsers < Base
      def call
        prompt = TTY::Prompt.new
        users  = Pgchief::User.all.join("\n")

        prompt.say users

        result = prompt.select("User management", [
                                 "Create user",
                                 "Drop user",
                                 "User list",
                                 "Grant database privileges",
                                 "View database connection string"
                               ])

        scope = result == "User list" ? "command" : "prompt"
        klassify(scope, result).call
      end
    end
  end
end
