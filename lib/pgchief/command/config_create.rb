# frozen_string_literal: true

require 'fileutils'

module Pgchief
  module Command
    # Create a configuration file at $HOME
    class ConfigCreate
      def self.call(dir: "#{Dir.home}/.config/pgchief")
        new.call(dir: dir)
      end

      def call(dir: "#{Dir.home}/.config/pgchief")
        return if File.exist?("#{dir}/config.toml")

        template = File.join(__dir__, '..', '..', '..', 'config', 'pgchief.toml')
        FileUtils.mkdir_p(dir)
        FileUtils.cp(template, "#{dir}/config.toml")

        puts "Configuration file created at #{dir}/config.toml"
      end
    end
  end
end
