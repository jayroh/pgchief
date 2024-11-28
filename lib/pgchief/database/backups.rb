# frozen_string_literal: true

require "forwardable"
require "pry"

module Pgchief
  class Database
    # Get a list of all backups for a given database
    class Backups
      extend Forwardable

      def_delegators :s3, :bucket, :path, :client

      def self.for(database, remote)
        new(database, remote).for
      end

      attr_reader :database, :remote

      def initialize(database, remote)
        @database = database
        @remote = remote
      end

      def for
        remote ? remote_backups : local_backups
      end

      def remote_backups
        @remote_backups ||= client.list_objects(
          bucket: bucket,
          prefix: "#{path}#{database}-"
        ).contents
                                  .map(&:key)
                                  .sort
                                  .last(3)
                                  .reverse
                                  .map { |f| File.basename(f) }
      end

      def local_backups
        Dir["#{Pgchief::Config.backup_dir}#{database}-*.dump"]
          .sort_by { |f| File.mtime(f) }
          .reverse
          .last(3)
          .map { |f| File.basename(f) }
      end

      private

      def s3
        Pgchief::Config.s3
      end
    end
  end
end
