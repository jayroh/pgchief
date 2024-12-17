# frozen_string_literal: true

module Pgchief
  module Prompt
    # Class to prompt for which user to drop
    class DropUser < Base
      def call
        user   = prompt.select("Which user needs to be deleted?", Pgchief::User.all)
        result = Pgchief::Command::UserDrop.call(user)

        prompt.say result

        return_to_main_menu
      end
    end
  end
end
