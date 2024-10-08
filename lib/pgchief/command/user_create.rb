# frozen_string_literal: true

module Pgchief
  module Command
    # Class to create a user
    class UserCreate < Base
      USER_OPTIONS = %w[
        NOINHERIT
        NOCREATEDB
        NOCREATEROLE
        NOSUPERUSER
        NOREPLICATION
      ].freeze

      attr_reader :username, :password

      def call
        @username, @password = params
        raise Pgchief::Errors::UserExistsError if user_exists?

        conn.exec("CREATE USER #{username} WITH #{user_options} PASSWORD '#{password}'")

        "User '#{username}' created successfully!"
      rescue PG::Error => e
        "Error: #{e.message}"
      ensure
        conn.close
      end

      private

      def user_exists?
        query = "SELECT 1 FROM pg_user WHERE usename = '#{username}'"
        conn.exec(query).any?
      end

      def user_options
        USER_OPTIONS.join(" ")
      end
    end
  end
end
