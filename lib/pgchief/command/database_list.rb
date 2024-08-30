# frozen_string_literal: true

module Pgchief
  module Command
    # Class to list databases
    class DatabaseList < Base
      def call
        prompt = TTY::Prompt.new
        databases = Pgchief::Database.all.join("\n")

        prompt.say databases
      end
    end
  end
end
