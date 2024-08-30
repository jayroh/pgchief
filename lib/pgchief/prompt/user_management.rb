# frozen_string_literal: true

module Pgchief
  module Prompt
    # Class to manage users
    class UserManagement < Base
      def self.call
        prompt = TTY::Prompt.new
        result = prompt.select("User management", ["Create user", "Drop user", "User list"])

        scope = result == "User list" ? "command" : "prompt"
        klassify(scope, result).call
      end
    end
  end
end
