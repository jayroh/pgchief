# frozen_string_literal: true

module Pgchief
  module Command
    # Class to grant database privileges
    class DatabasePrivilegesGrant < Base
      attr_reader :username

      def initialize(*params) # rubocop:disable Lint/MissingSuper
        @params = params
        @username = params.first
      end

      def call
        databases = params.last

        databases.each do |database|
          grant_privs_to(database)
        end

        "Privileges granted to #{username} on #{databases.join(", ")}"
      end

      private

      def grant_privs_to(database) # rubocop:disable Metrics/MethodLength
        conn = PG.connect("#{DATABASE_URL}/#{database}")
        conn.exec("GRANT CONNECT ON DATABASE #{database} TO #{username};")
        conn.exec("GRANT CREATE ON SCHEMA public TO #{username};")
        conn.exec("GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO #{username};")
        conn.exec("GRANT USAGE ON SCHEMA public TO #{username};")
        conn.exec(
          <<~SQL
            ALTER DEFAULT PRIVILEGES IN SCHEMA public
            GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES
            TO #{username};
          SQL
        )
        conn.close
      rescue PG::Error => e
        "Error: #{e.message}"
      ensure
        conn.finished? || conn.close
      end
    end
  end
end
