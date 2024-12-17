# frozen_string_literal: true

module Pgchief
  module Prompt
    # Class that exits out of the program
    class Quit < Base
      def call
        prompt.say("Exiting! Farewell! 👋")
        exit
      end
    end
  end
end
