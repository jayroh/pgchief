# frozen_string_literal: true

module Pgchief
  # Class to parse and manipulate connection strings
  class ConnectionString
    URL_REGEX = %r{(?x)\A
      postgres(ql)?://
      (?<username>[^:@]*)?
      :?(?<password>[^@]*)?
      @?(?<host>[^:]*)?
      :?(?<port>\d+)?
      /?(?<database>[^\?]*)?
      \z}

    attr_reader :database_url

    def initialize(
      database_url,
      username: nil,
      password: nil,
      host: nil,
      port: nil,
      database: nil
    )
      @database_url = database_url
      @host = host
      @username = username
      @password = password
      @port = port
      @database = database
    end

    def to_s
      "postgresql://#{username}:#{password}@#{host}:#{port}/#{database}"
    end

    def host
      @host || (matched[:username] if matched[:host].empty?) || matched[:host]
    end

    def username
      @username || ("" if matched[:host].empty? && !matched[:username].empty?) || matched[:username] || ""
    end

    def password
      @password || matched[:password] || ""
    end

    def port
      @port || matched[:port] || "5432"
    end

    def database
      @database || matched[:database] || ""
    end

    private

    def matched
      @matched ||= database_url.match(URL_REGEX) || {}
    end
  end
end
