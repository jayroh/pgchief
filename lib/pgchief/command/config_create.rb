# frozen_string_literal: true

require "fileutils"

module Pgchief
  module Command
    # Create a configuration file at $HOME
    class ConfigCreate < Base
      def call
        return if File.exist?("#{Dir.home}/.pgchief.toml")

        FileUtils.cp(
          File.join(__dir__, "..", "..", "..", "config", "pgchief.toml"),
          "#{Dir.home}/.pgchief.toml"
        )

        puts "Configuration file created at #{Dir.home}/.pgchief.toml"
      end
    end
  end
end
