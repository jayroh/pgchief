# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pgchief::Command::DatabaseBackup do
  it "raises an error if the database does not exist" do
    expect { described_class.new("nonexistent").call }
      .to raise_error(Pgchief::Errors::DatabaseMissingError)
  end

  context "when the database exists" do
    around do |example|
      Pgchief::Config.backup_dir = "/tmp"
      Pgchief::Command::DatabaseCreate.new("backup_test").call

      example.run

      Pgchief::Command::DatabaseDrop.new("backup_test").call
      Dir.glob("/tmp/backup_test-*.dump").each { |f| File.delete(f) }
    end

    it "backs up the database" do
      result = described_class.new("backup_test").call
      message = %r{Database 'backup_test' backed up to /tmp/.*.dump}

      expect(result).to match(message)
    end

    it "raises an error if the backup file is 0 bytes" do
      allow(File).to receive(:size?).and_return(nil)

      expect { described_class.new("backup_test").call }
        .to raise_error(Pgchief::Errors::BackupError)
    end
  end
end
