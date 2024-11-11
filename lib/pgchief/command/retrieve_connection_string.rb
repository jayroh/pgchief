# frozen_string_literal: true

module Pgchief
  module Command
    # Class to view database connection string
    class RetrieveConnectionString < Base
      attr_reader :username, :database

      def initialize(username, database = nil)
        @username = username
        @database = database
        @connection_string = nil
      end

      def call
        File.foreach(Config.credentials_file) do |line|
          @connection_string = line if regex.match?(line)
        end

        @connection_string.nil? ? "No connection string found" : @connection_string
      end

      private

      def regex
        if database
          /#{username}.*#{database}$/
        else
          /#{username}.*\d$/
        end
      end
    end
  end
end
