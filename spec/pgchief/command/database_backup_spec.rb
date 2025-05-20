# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pgchief::Command::DatabaseBackup do
  it 'raises an error if the database does not exist' do
    expect { described_class.new('nonexistent').call }
      .to raise_error(Pgchief::Errors::DatabaseMissingError)
  end

  context 'when the database exists' do
    around do |example|
      original_db_url = ENV.fetch('DATABASE_URL', nil)
      Pgchief::Config.backup_dir = '/tmp'
      Pgchief::Config.s3_key     = nil
      Pgchief::Config.s3_secret  = nil
      Pgchief::Command::DatabaseDrop.new('backup_test').call
      Pgchief::Command::DatabaseCreate.new('backup_test').call

      example.run

      Pgchief::Command::DatabaseDrop.new('backup_test').call
      Dir.glob('/tmp/backup_test-*.dump').each { |f| File.delete(f) }
      ENV['DATABASE_URL'] = original_db_url
    end

    it 'backs up the database' do
      result = described_class.new('backup_test').call
      message = %r{Database 'backup_test' backed up to /tmp/.*.dump}

      expect(result).to match(message)
    end

    it 'uses correct db if there is already one at the end of the url string' do
      Pgchief::Command::DatabaseDrop.new('another_db').call
      Pgchief::Command::DatabaseCreate.new('another_db').call
      ENV['DATABASE_URL'] = 'postgresql://postgres@localhost:5432/another_db'
      result = described_class.new('backup_test').call
      message = %r{Database 'backup_test' backed up to /tmp/.*.dump}

      expect(result).to match(message)

      Pgchief::Command::DatabaseDrop.new('another_db').call
    end

    it 'raises an error if the backup file is 0 bytes' do
      allow(File).to receive(:size?).and_return(nil)

      expect { described_class.new('backup_test').call }
        .to raise_error(Pgchief::Errors::BackupError)
    end
  end
end
