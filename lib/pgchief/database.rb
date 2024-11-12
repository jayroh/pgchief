# frozen_string_literal: true

require "pg"

module Pgchief
  # Database information and operations
  class Database
    def self.all
      conn = PG.connect(Pgchief::Config.pgurl)
      result = conn.exec("SELECT datname FROM pg_database WHERE datistemplate = false")
      result
        .map { |row| row["datname"] }
        .reject { |name| name == "postgres" }
    ensure
      conn.close
    end
  end
end
