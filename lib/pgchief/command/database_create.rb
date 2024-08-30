# frozen_string_literal: true

module Pgchief
  module Command
    # Command object to create a database
    class DatabaseCreate < Base
      attr_reader :database

      def call
        @database = params.first
        raise Pgchief::Errors::DatabaseExistsError if db_exists?

        conn.exec("CREATE DATABASE #{database}")
        conn.exec("REVOKE CONNECT ON DATABASE #{database} FROM PUBLIC")

        "Database '#{database}' created successfully!"
      rescue PG::Error => e
        "Error: #{e.message}"
      ensure
        conn.close
      end

      private

      def db_exists?
        query = "SELECT 1 FROM pg_database WHERE datname = '#{database}'"
        conn.exec(query).any?
      end
    end
  end
end
