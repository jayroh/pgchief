# frozen_string_literal: true

require "extensions/string"

module Pgchief
  module Command
    # Class to view database connection string
    class RetrieveConnectionString < Base
      attr_reader :username, :database, :secret, :encrypted_line

      def initialize(username, secret = Config.credentials_secret, database = nil)
        @username = username
        @secret   = secret
        @database = database

        @encrypted_line = nil
      end

      def call
        return if secret.nil?

        File.foreach(Config.credentials_file) do |line|
          @encrypted_line = line if /#{key}:/.match?(line)
        end

        return "No connection string found" if @encrypted_line.nil?

        @encrypted_line.split(":").last.decrypt(secret)
      end

      private

      def key
        @key = username.dup
        @key << ":#{database}" if database
        @key = @key.encrypt(secret)
      end
    end
  end
end
