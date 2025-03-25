# frozen_string_literal: true

require 'pg'

module Pgchief
  # Database information and operations
  class User
    def self.all
      conn   = PG.connect(Pgchief::Config.pgurl)
      result = conn.exec('SELECT usename FROM pg_user')

      result.map { |row| row['usename'] }.reject { |name| name == 'postgres' }
    ensure
      conn.close
    end
  end
end
