# frozen_string_literal: true

module Pgchief
  module Prompt
    # Class to ask for database names, in order to create it
    class GrantDatabasePrivileges
      def self.call(username)
        databases = Pgchief::Database.all
        prompt = TTY::Prompt.new
        databases = prompt.select("Select database:", databases, multiselect: true)
        Pgchief::Command::GrantDatabasePrivileges.call(username, databases)
      end
    end
  end
end
