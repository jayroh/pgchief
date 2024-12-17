# frozen_string_literal: true

require "forwardable"

module Pgchief
  module Command
    # Command object to back up a database
    class DatabaseBackup < Base
      extend Forwardable

      def_delegators :@uploader, :configured?, :upload!, :s3_location

      attr_reader :database

      def initialize(*params)
        super
        @database = params.first
        @uploader = Pgchief::Command::S3Upload.new(local_location)
      end

      def call
        raise Pgchief::Errors::DatabaseMissingError unless db_exists?

        backup!
        check_backup!
        upload! if configured?

        "Database '#{database}' backed up to #{location}"
      rescue PG::Error => e
        "Error: #{e.message}"
      ensure
        conn.close
      end

      private

      def backup!
        `pg_dump -Fc #{Pgchief::Config.pgurl}/#{database} -f #{local_location}`
      end

      def check_backup!
        raise Pgchief::Errors::BackupError, "Backup file has 0 bytes" unless File.size?(local_location)
      end

      def db_exists?
        query = "SELECT 1 FROM pg_database WHERE datname = '#{database}'"
        conn.exec(query).any?
      end

      def location
        configured? ? s3_location : local_location
      end

      def local_location
        @local_location ||= begin
          timestamp = Time.now.strftime("%Y%m%d%H%M%S")
          "#{Pgchief::Config.backup_dir}#{database}-#{timestamp}.dump"
        end
      end
    end
  end
end
