# frozen_string_literal: true

module Pgchief
  module Command
    # Class to store connection string
    class StoreConnectionString
      def self.call(
        username,
        connection_string,
        secret = Config.credentials_secret,
        database = nil
      )
        new(username, connection_string, secret, database).call
      end

      attr_reader :username, :secret, :password, :database

      def initialize(
        username,
        connection_string,
        secret = Config.credentials_secret,
        database = nil
      )
        @username          = username
        @secret            = secret
        @connection_string = connection_string
        @database          = database
      end

      def call
        return if secret.nil?

        File.open(Config.credentials_file, "a") do |file|
          file.puts "#{key}:#{@connection_string.encrypt(@secret)}"
        end
      end

      private

      def key
        @key = @username.dup
        @key << ":#{@database}" if @database
        @key.encrypt(@secret)
      end
    end
  end
end
