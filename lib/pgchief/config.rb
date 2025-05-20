# frozen_string_literal: true

require 'toml-rb'

module Pgchief
  # Class to store configuration settings
  class Config
    DEFAULT_CONFIG = "#{Dir.home}/.config/pgchief/config.toml".freeze

    class << self
      attr_accessor \
        :s3_key,
        :s3_secret,
        :s3_region,
        :remote_restore,
        :remote_backup

      attr_writer :pgurl

      attr_reader \
        :s3_objects_path,
        :backup_dir,
        :credentials_file,
        :toml_file

      # explicitly define getter so that pgurl is always available if
      # load_config! is not run.
      def pgurl
        ENV.fetch('DATABASE_URL', ENV.fetch('DB_URL', @pgurl))
      end

      def load_config!(params, toml_file = DEFAULT_CONFIG)
        @toml_file            = toml_file
        config                = toml_config || env_config
        self.backup_dir       = config[:backup_dir]
        self.credentials_file = config[:credentials_file]
        self.pgurl            = config[:pgurl]
        self.s3_key           = config[:s3_key]
        self.s3_secret        = config[:s3_secret]
        self.s3_region        = config[:s3_region]
        self.s3_objects_path  = config[:s3_objects_path] || config[:s3_path_prefix]
        self.remote_restore   = params[:'remote-restore'] == true ||
                                params[:'local-restore'] == false ||
                                config[:remote_restore]
        self.remote_backup    = params[:'remote-backup']  == true ||
                                params[:'local-backup'] == false ||
                                config[:remote_backup]
      rescue Pgchief::Errors::ConfigMissingError
        puts config_missing_error(toml_file)
      end

      def s3
        @s3 ||= Pgchief::Config::S3.new(self)
      end

      def backup_dir=(value)
        @backup_dir = value ? "#{value.chomp('/')}/".gsub('~', Dir.home) : '/tmp/'
      end

      def s3_objects_path=(value)
        @s3_objects_path = value ? "#{value.chomp('/')}/" : nil
      end

      def credentials_file=(value)
        @credentials_file = value&.gsub('~', Dir.home)
      end

      def set_up_file_structure!
        FileUtils.mkdir_p(backup_dir)
        return unless credentials_file && !File.exist?(credentials_file)

        FileUtils.touch(credentials_file)
      end

      private

      def toml_config
        return unless File.exist?(toml_file.to_s)

        TomlRB.load_file(toml_file, symbolize_keys: true)
      end

      def env_config
        pgurl = ENV.fetch('DATABASE_URL', ENV.fetch('DB_URL', nil))
        raise Pgchief::Errors::ConfigMissingError if pgurl.nil?

        {
          pgurl: pgurl,
          s3_key: ENV.fetch('AWS_ACCESS_KEY_ID', ENV.fetch('AWS_ACCESS_KEY', nil)),
          s3_secret: ENV.fetch('AWS_SECRET_ACCESS_KEY', ENV.fetch('AWS_SECRET_KEY', nil)),
          s3_region: ENV.fetch('AWS_DEFAULT_REGION', ENV.fetch('AWS_REGION', nil)),
          s3_objects_path: ENV.fetch('S3_BACKUPS_PATH', nil)
        }
      end

      def config_missing_error(toml_file)
        "You must create a config file at #{toml_file || DEFAULT_CONFIG}.\n" \
          'run `pgchief --init` to create it.'
      end
    end
  end
end
