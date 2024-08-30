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
        @conn = PG.connect(ENV.fetch("DATABASE_URL"))
      end

      def call
        raise NotImplementedError
      end
    end
  end
end
