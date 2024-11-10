# frozen_string_literal: true

module Pgchief
  module Command
    # Class to store connection string
    class StoreConnectionString
      def self.call(connection_string)
        new(connection_string).call
      end

      attr_reader :connection_string

      def initialize(connection_string)
        @connection_string = connection_string
      end

      def call
        File.open(Config.credentials_file, "a") do |file|
          file.puts @connection_string
        end
      end
    end
  end
end
