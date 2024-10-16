# frozen_string_literal: true

require "fileutils"

module Pgchief
  module Command
    # Create a configuration file at $HOME
    class ConfigCreate < Base
      def call(dir: Dir.home)
        return if File.exist?("#{dir}/.pgchief.toml")

        FileUtils.cp(
          File.join(__dir__, "..", "..", "..", "config", "pgchief.toml"),
          "#{dir}/.pgchief.toml"
        )

        puts "Configuration file created at #{dir}/.pgchief.toml"
      end
    end
  end
end
