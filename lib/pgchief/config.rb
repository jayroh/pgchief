# frozen_string_literal: true

require "toml-rb"

module Pgchief
  # Class to store configuration settings
  class Config
    class << self
      attr_accessor \
        :s3_key,
        :s3_secret,
        :s3_region

      attr_writer :pgurl

      attr_reader \
        :s3_objects_path,
        :backup_dir,
        :credentials_file

      def load_config!(toml_file = "#{Dir.home}/.config/pgchief/config.toml") # rubocop:disable Metrics/AbcSize
        config                = TomlRB.load_file(toml_file, symbolize_keys: true)
        self.backup_dir       = config[:backup_dir]
        self.credentials_file = config[:credentials_file]
        self.pgurl            = config[:pgurl]
        self.s3_key           = config[:s3_key]
        self.s3_secret        = config[:s3_secret]
        self.s3_region        = config[:s3_region]
        self.s3_objects_path  = config[:s3_objects_path] || config[:s3_path_prefix]
      rescue Errno::ENOENT
        puts config_missing_error(toml_file)
      end

      def s3
        @s3 ||= Pgchief::Config::S3.new(self)
      end

      def pgurl
        ENV.fetch("DATABASE_URL", @pgurl)
      end

      def backup_dir=(value)
        @backup_dir = value ? "#{value.chomp("/")}/".gsub("~", Dir.home) : "/tmp/"
      end

      def s3_objects_path=(value)
        @s3_objects_path = value ? "#{value.chomp("/")}/" : nil
      end

      def credentials_file=(value)
        @credentials_file = value&.gsub("~", Dir.home)
      end

      def set_up_file_structure!
        FileUtils.mkdir_p(backup_dir)
        return unless credentials_file && !File.exist?(credentials_file)

        FileUtils.touch(credentials_file)
      end

      private

      def config_missing_error(toml_file)
        "You must create a config file at #{toml_file}.\n" \
          "run `pgchief --init` to create it."
      end
    end
  end
end
