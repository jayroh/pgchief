# frozen_string_literal: true

module Pgchief
  module Command
    # Command object to drop a database
    class DatabaseDrop < Base
      attr_reader :database

      def call
        @database = params.first

        return "Database '#{database}' does not exist." unless db_exists?

        conn.exec("DROP DATABASE #{database}")
        "Database '#{database}' dropped successfully!"
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
