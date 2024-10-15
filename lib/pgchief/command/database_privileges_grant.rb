# frozen_string_literal: true

module Pgchief
  module Command
    # Class to grant database privileges
    class DatabasePrivilegesGrant < Base

      def initialize(*params)
        @params = params
      end

      def call
        username = params.first
        databases = params.last

        databases.each do |database|
          conn = PG.connect("#{DATABASE_URL}/#{database}")
          conn.exec("GRANT CONNECT ON DATABASE #{database} TO #{username};")
          conn.exec("GRANT CREATE ON SCHEMA public TO #{username};")
          conn.exec("GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO #{username};")
          conn.exec("GRANT USAGE ON SCHEMA public TO #{username};")
          conn.exec("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO #{username};")
          conn.close
        rescue PG::Error => e
          "Error: #{e.message}"
        ensure
          conn.finished? || conn.close
        end

        "Privileges granted to #{username} on #{databases.join(", ")}"
      end
    end
  end
end
