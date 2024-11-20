# frozen_string_literal: true

require "toml-rb"

module Pgchief
  # Class to store configuration settings
  class Config
    class << self
      attr_accessor \
        :backup_dir,
        :credentials_file

      attr_writer :pgurl

      def load_config!(toml_file = "#{Dir.home}/.config/pgchief/config.toml")
        config = TomlRB.load_file(toml_file, symbolize_keys: true)

        @backup_dir = config[:backup_dir].gsub("~", Dir.home)
        @credentials_file = config[:credentials_file]&.gsub("~", Dir.home)
        @pgurl = config[:pgurl]
      rescue Errno::ENOENT
        puts "You must create a config file at #{toml_file}."
        puts "run `pgchief --init` to create it."
      end

      def pgurl
        ENV.fetch("DATABASE_URL", @pgurl)
      end

      def set_up_file_structure!
        FileUtils.mkdir_p(backup_dir)

        return unless credentials_file && !File.exist?(credentials_file)

        FileUtils.touch(credentials_file)
      end
    end
  end
end
