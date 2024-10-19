# frozen_string_literal: true

module Pgchief
  module Prompt
    # Class to ask for database names, in order to create it
    class ViewDatabaseConnectionString < Base
      def call
        username  = params.first || select_user
        databases = prompt.select("Database you're connecting to:", Pgchief::Database.all)
        secret    = prompt.mask("Enter secret/password:")
        result    = Pgchief::Command::RetrieveConnectionString.call(username, databases, secret)

        prompt.say result
      end

      def select_user
        prompt.select("Select user to update:", Pgchief::User.all)
      end
    end
  end
end
