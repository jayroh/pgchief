# frozen_string_literal: true

module Pgchief
  module Command
    # Base class for commands
    class Base
      def self.call(*params)
        new(*params).call
      end

      attr_reader :params, :conn

      def initialize(*params)
        @params = params
        @conn = PG.connect(Pgchief::Config.pgurl)
      rescue PG::ConnectionBad => e
        puts "Cannot connect to database. #{e.message}"
      end

      def call
        raise NotImplementedError
      end
    end
  end
end
