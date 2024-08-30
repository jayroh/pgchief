# frozen_string_literal: true

module Pgchief
  module Command
    # Class to drop a user
    class UserDrop < Base
      attr_reader :username

      def call
        @username = params.first
        raise Pgchief::Errors::UserExistsError unless user_exists?

        conn.exec("DROP USER #{username}")

        "User '#{username}' dropped successfully!"
      rescue PG::Error => e
        "Error: #{e.message}"
      ensure
        conn.close
      end

      def user_exists?
        query = "SELECT 1 FROM pg_user WHERE usename = '#{username}'"
        conn.exec(query).any?
      end
    end
  end
end
