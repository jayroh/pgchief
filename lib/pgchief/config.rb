# frozen_string_literal: true

require "toml-rb"

module Pgchief
  # Class to store configuration settings
  class Config
    class << self
      attr_accessor \
        :backup_dir,
        :credentials_file,
        :credentials_secret,
        :pgurl

      def load_config!(toml_file = "#{Dir.home}/.config/pgchief/config.toml")
        config = TomlRB.load_file(toml_file, symbolize_keys: true)

        @backup_dir = config[:backup_dir].gsub("~", Dir.home)
        @credentials_file = config[:credentials_file]&.gsub("~", Dir.home)
        @pgurl = config[:pgurl]
      end

      def set_up_file_structure!
        FileUtils.mkdir_p(backup_dir)

        return unless credentials_file && !File.exist?(credentials_file)

        FileUtils.touch(credentials_file)
      end
    end
  end
end
