# frozen_string_literal: true

module Pgchief
  module Prompt
    # Base class for prompt classes
    class Base
      def self.class
        raise "Method not defined"
      end

      def self.klassify(scope, words)
        Object.const_get([
          "Pgchief", "::", scope.capitalize, "::",
          words.split.map(&:capitalize)
        ].flatten.join)
      end
    end
  end
end
