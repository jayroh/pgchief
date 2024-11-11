# frozen_string_literal: true

module Pgchief
  module Command
    # Class to drop a user
    class UserDrop < Base
      attr_reader :username

      def call
        @username = params.first
        raise Pgchief::Errors::UserExistsError unless user_exists?

        revoke_all_privileges
        drop_user

        "User '#{username}' dropped successfully!"
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

      def revoke_all_privileges
        databases_with_access.each do |database|
          conn.exec("REVOKE ALL PRIVILEGES ON DATABASE #{database} FROM #{username};")
        rescue PG::Error
          next
        end
      end

      def drop_user
        conn.exec("DROP USER #{username}")
      end

      def databases_with_access
        @databases_with_access ||= begin
          results = conn.exec <<~SQL
            SELECT datname
            FROM pg_database
            WHERE has_database_privilege('#{username}', datname, 'CONNECT')
              AND datname NOT IN ('postgres', 'template1', 'template0')
          SQL

          results.map { |row| row["datname"] }
        end
      end
    end
  end
end
