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

      def load_config!(toml_file = "~/.config/pgchief/config.toml")
        config = TomlRB.load_file(toml_file, symbolize_keys: true)

        @backup_dir = config[:backup_dir]
        @credentials_file = config[:credentials_file]
        @pgurl = config[:pgurl]
      end
    end
  end
end
