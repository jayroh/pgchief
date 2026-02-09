# frozen_string_literal: true

require 'pgchief/validators'

module Pgchief
  module Command
    # Command object to drop a database
    class DatabaseDrop < Base
      attr_reader :database

      def call
        @database = Pgchief::Validators.sanitize_identifier(params.first)

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
        query = 'SELECT 1 FROM pg_database WHERE datname = $1'
        conn.exec_params(query, [database]).any?
      end
    end
  end
end
