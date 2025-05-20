# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pgchief::Config do
  around do |example|
    original_env = ENV.fetch('DATABASE_URL', nil)
    ENV['DATABASE_URL'] = nil

    example.run

    ENV['DATABASE_URL'] = original_env
  end

  it 'prints out an error if no pg url is set' do
    toml_file = nil
    expected_first = "You must create a config file at #{toml_file}."
    expected_second = 'run `pgchief --init` to create it.'
    expected_regex = /#{expected_first}.*#{expected_second}/m

    expect { described_class.load_config!({}, toml_file) }
      .to output(expected_regex).to_stdout
  end

  it 'works fine when env DATABASE_URL is set' do
    toml_file = nil
    expected_first = "You must create a config file at #{toml_file}."
    expected_second = 'run `pgchief --init` to create it.'
    expected_regex = /#{expected_first}.*#{expected_second}/m
    ENV['DATABASE_URL'] = 'postgresql://localhost:5432'

    expect { described_class.load_config!({}, toml_file) }
      .not_to output(expected_regex).to_stdout
  end

  it 'allows setting and getting of configuration settings' do
    described_class.credentials_file = 'credentials_file'
    described_class.pgurl = 'postgresql://localhost:5432'
    described_class.backup_dir = '/tmp'

    expect(described_class.credentials_file).to eq('credentials_file')
    expect(described_class.pgurl).to eq('postgresql://localhost:5432')
    expect(described_class.backup_dir).to eq('/tmp/')
  end

  context 'when there is no config, but some ENV variables' do
    before do
      ENV['DATABASE_URL'] = 'postgresql://testhost:5432'
    end

    it 'uses the provided db url env' do
      described_class.load_config!({}, nil)

      expect(described_class.pgurl).to eq('postgresql://testhost:5432')
    end

    it 'uses the provided S3 ENVs' do
      ENV['AWS_ACCESS_KEY_ID'] = 'KEY'
      ENV['AWS_SECRET_ACCESS_KEY'] = 'SECRET'
      ENV['AWS_DEFAULT_REGION'] = 'REGION'
      ENV['S3_BACKUPS_PATH'] = 's3://bucket-name/database-backups/'

      described_class.load_config!({}, nil)

      expect(described_class.s3_key).to eq('KEY')
      expect(described_class.s3_secret).to eq('SECRET')
      expect(described_class.s3_region).to eq('REGION')
      expect(described_class.s3_objects_path).to eq('s3://bucket-name/database-backups/')
    end
  end

  context 'when config file(s) exist' do
    it 'loads default configuration settings from a TOML file' do
      toml_file = File.expand_path('spec/fixtures/config_default.toml')

      described_class.load_config!({}, toml_file)

      expect(described_class.pgurl).to eq('postgresql://localhost:5432')
      expect(described_class.backup_dir).to eq('/tmp/')
      expect(described_class.credentials_file).to be_nil
      expect(described_class.remote_restore).to be_falsey
    end

    it 'loads different configuration settings from a TOML file' do
      toml_file = File.expand_path('spec/fixtures/config_with_credentials_file.toml')

      described_class.load_config!({}, toml_file)

      expect(described_class.pgurl).to eq('postgresql://localhost:5432')
      expect(described_class.backup_dir).to eq('/tmp/backups/')
      expect(described_class.credentials_file).to eq("#{Dir.home}/creds")
    end

    it "uses /tmp as the backup location if it's not set in the config" do
      toml_file = File.expand_path('spec/fixtures/config_default.toml')

      described_class.load_config!({}, toml_file)
      described_class.backup_dir = nil

      expect(described_class.backup_dir).to eq('/tmp/')
    end

    it 'adds a trailing slash to the local backup path' do
      toml_file = File.expand_path('spec/fixtures/config_default.toml')

      described_class.load_config!({}, toml_file)
      described_class.backup_dir = '/tmp'

      expect(described_class.backup_dir).to eq('/tmp/')
    end

    context 'when the config file has a s3 section' do
      it 'loads the s3 settings' do
        toml_file = File.expand_path('spec/fixtures/config_with_s3.toml')

        described_class.load_config!({}, toml_file)

        expect(described_class.s3_key).to eq('KEY')
        expect(described_class.s3_secret).to eq('SECRET')
        expect(described_class.s3_region).to eq('us-east-1')
        expect(described_class.s3_objects_path).to eq('s3://bucket/path/')
        expect(described_class.remote_restore).to be_truthy
      end

      it 'ensures the path prefix ends with a slash' do
        toml_file = File.expand_path('spec/fixtures/config_with_s3.toml')

        described_class.load_config!({}, toml_file)
        described_class.s3_objects_path = 's3://custom/path'

        expect(described_class.s3_objects_path).to eq('s3://custom/path/')
      end
    end
  end
end
