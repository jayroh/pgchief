# frozen_string_literal: true

module Pgchief
  module Command
    # Class to grant database privileges
    class DatabasePrivilegesGrant < Base
      attr_reader :username, :password, :database

      def initialize(*params)
        @username = params[0]
        @password = params[1]
        @databases = params[2]
      end

      def call
        @databases.each do |database|
          @database = database
          grant_privs!
          store_credentials!
        end

        "Privileges granted to #{username} on #{@databases.join(", ")}"
      end

      private

      def grant_privs! # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        conn = PG.connect("#{Pgchief::Config.pgurl}/#{database}")
        conn.exec("GRANT CONNECT ON DATABASE #{database} TO #{username};")
        conn.exec("GRANT CREATE ON DATABASE #{database} TO #{username};")
        conn.exec("GRANT USAGE ON SCHEMA pg_catalog TO #{username};")
        conn.exec("GRANT CREATE ON SCHEMA pg_catalog TO #{username};")
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

      def store_credentials!
        Pgchief::Command::StoreConnectionString.call(connection_string)
      end

      def connection_string
        ConnectionString.new(
          Pgchief::Config.pgurl,
          username: username,
          password: password,
          database: database
        ).to_s
      end
    end
  end
end
