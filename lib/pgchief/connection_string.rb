# frozen_string_literal: true

module Pgchief
  class ConnectionString
    URL_REGEX = %r((?x)\A
      postgres(ql)?://
      (?<username>.*):
      (?<password>.*)@
      (?<host>.*):(?<port>\d+)/
      (?<database>.*)
      (\?sslmode=(?<sslmode>.*))
      \z)

    attr_reader \
      :database_url,
      :username,
      :password,
      :host,
      :port,
      :database,
      :sslmode

    def initialize(
      database_url,
      username: nil,
      password: nil,
      host: nil,
      port: nil,
      database: nil,
      sslmode: nil
    )
      @database_url = database_url

      @username = username || matched[:username] || "postgres"
      @password = password || matched[:password]
      @host = host || matched[:host] || "localhost"
      @port = port || matched[:port] || "5432"
      @database = database || matched[:database]
      @sslmode = sslmode || matched[:sslmode]
    end

    def to_s
      "postgresql://#{username}:#{password}@#{host}:#{port}/#{database}?sslmode=#{sslmode}"
    end

    private

    def matched
      @matched ||= database_url.match(/URL_REGEX/) || {}
    end
  end
end
