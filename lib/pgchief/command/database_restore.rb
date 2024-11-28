# frozen_string_literal: true

require "forwardable"

module Pgchief
  module Command
    # Command object to restore a database
    class DatabaseRestore < Base
      extend Forwardable

      attr_reader :database, :filename

      def call
        @database = params.first
        @filename = params.last
        raise Pgchief::Errors::DatabaseMissingError unless db_exists?

        restore!

        "Database '#{database}' restored from #{filename}"
      rescue PG::Error => e
        "Error: #{e.message}"
      ensure
        conn.close
      end

      private

      def restore!
        `pg_restore --clean --no-owner --dbname=#{Pgchief::Config.pgurl}/#{database} #{local_location}`
      end

      def db_exists?
        query = "SELECT 1 FROM pg_database WHERE datname = '#{database}'"
        conn.exec(query).any?
      end

      def local_location
        "#{Pgchief::Config.backup_dir}/#{filename}"
      end
    end
  end
end
