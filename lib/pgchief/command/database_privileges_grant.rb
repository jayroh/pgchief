# frozen_string_literal: true

module Pgchief
  module Command
    # Class to grant database privileges
    class DatabasePrivilegesGrant < Base
      def call
        username = params.first
        databases = params.last

        databases.each do |database|
          conn.exec("GRANT CONNECT ON DATABASE #{database} TO #{username};")
        end

        "Privileges granted to #{username} on #{databases.join(", ")}"
      rescue PG::Error => e
        "Error: #{e.message}"
      ensure
        conn.close
      end
    end
  end
end
