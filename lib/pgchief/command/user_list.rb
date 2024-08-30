# frozen_string_literal: true

module Pgchief
  module Command
    # Class to list databases
    class UserList < Base
      def call
        prompt = TTY::Prompt.new
        users  = Pgchief::User.all.join("\n")

        prompt.say users
      end
    end
  end
end
