# frozen_string_literal: true

require 'pgchief/validators'

module Pgchief
  module Command
    # Command object to create a database
    class DatabaseCreate < Base
      attr_reader :database

      def call
        @database = Pgchief::Validators.sanitize_identifier(params.first)
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
        query = 'SELECT 1 FROM pg_database WHERE datname = $1'
        conn.exec_params(query, [database]).any?
      end
    end
  end
end
