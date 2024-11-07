# frozen_string_literal: true

module Pgchief
  module Command
    # Class to store connection string
    class StoreConnectionString
      def self.call(
        key,
        connection_string,
        secret = Config.credentials_secret
      )
        new(key, connection_string, secret).call
      end

      attr_reader :key, :connection_string, :secret

      def initialize(
        key,
        connection_string,
        secret = Config.credentials_secret
      )
        @key               = key
        @connection_string = connection_string
        @secret            = secret
      end

      def call
        return if secret.nil?

        File.open(Config.credentials_file, "a") do |file|
          file.puts "#{key.encrypt(@secret)}:#{@connection_string.encrypt(@secret)}"
        end
      end
    end
  end
end
