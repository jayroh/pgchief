# frozen_string_literal: true

module Pgchief
  module Prompt
    # Class to prompt for user creation details
    class CreateUser < Base
      def self.call
        prompt   = TTY::Prompt.new
        username = prompt.ask("Username:")
        password = prompt.mask("Password:")
        result   = Pgchief::Command::UserCreate.call(username, password)

        prompt.say result
      end
    end
  end
end
