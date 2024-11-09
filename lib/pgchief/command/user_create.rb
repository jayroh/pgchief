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

        create_user!
        save_credentials!

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

      def create_user!
        conn.exec("CREATE USER #{username} WITH #{user_options} PASSWORD '#{password}'")
      end

      def save_credentials!
        Pgchief::Command::StoreConnectionString.call(connection_string)
      end

      def user_options
        USER_OPTIONS.join(" ")
      end

      def connection_string
        ConnectionString.new(
          Pgchief::DATABASE_URL,
          username: username,
          password: password
        ).to_s
      end
    end
  end
end
