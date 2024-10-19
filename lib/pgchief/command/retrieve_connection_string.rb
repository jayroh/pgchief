# frozen_string_literal: true
#
module Pgchief
  module Command
    # Class to view database connection string
    class RetrieveConnectionString < Base
      def call
        username = params[0]
        database = params[1]
        secret   = params[2]

        puts params.join(" ")
      end
    end
  end
end
