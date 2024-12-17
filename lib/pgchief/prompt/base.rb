# frozen_string_literal: true

module Pgchief
  module Prompt
    # Base class for prompt classes
    class Base
      def self.call(*params)
        new(*params).call
      end

      attr_reader :params

      def initialize(*params)
        @params = params
      end

      def call
        raise NotImplementedError
      end

      def klassify(scope, words)
        Object.const_get([
          "Pgchief", "::", scope.capitalize, "::",
          words.split.map(&:capitalize)
        ].flatten.join)
      end

      def yes_or_no(question, yes: nil, no: nil) # rubocop:disable Naming/MethodParameterName
        response = prompt.yes?(question)
        response ? yes&.call : no&.call
      end

      def prompt
        @prompt ||= TTY::Prompt.new.tap do |p|
          p.on(:keypress) do |event|
            p.trigger(:keydown) if event.value == "j"
            p.trigger(:keyup) if event.value == "k"
          end

          p.on(:keyescape) do
            p.say "\n\nExiting...bye-bye 👋\n\n"
            exit
          end
        end
      end

      def return_to_main_menu
        Pgchief::Prompt::Start.call("What's next?")
      end
    end
  end
end
