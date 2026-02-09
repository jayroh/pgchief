# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/validators'

RSpec.describe Pgchief::Validators do
  describe '.valid_identifier?' do
    it 'returns true for valid identifiers' do
      expect(described_class.valid_identifier?('my_database')).to be true
      expect(described_class.valid_identifier?('user123')).to be true
      expect(described_class.valid_identifier?('test_db_2')).to be true
    end

    it 'returns false for identifiers with special characters' do
      expect(described_class.valid_identifier?('my-database')).to be false
      expect(described_class.valid_identifier?('user@123')).to be false
      expect(described_class.valid_identifier?('test;drop')).to be false
    end

    it 'returns false for identifiers with SQL injection attempts' do
      expect(described_class.valid_identifier?("'; DROP TABLE users--")).to be false
      expect(described_class.valid_identifier?('admin" OR "1"="1')).to be false
    end

    it 'returns false for empty or nil identifiers' do
      expect(described_class.valid_identifier?('')).to be false
      expect(described_class.valid_identifier?(nil)).to be false
    end

    it 'returns false for identifiers that are too long' do
      expect(described_class.valid_identifier?('a' * 64)).to be false
    end
  end

  describe '.sanitize_identifier' do
    it 'raises error for invalid identifiers' do
      expect { described_class.sanitize_identifier('bad;name') }
        .to raise_error(Pgchief::Errors::InvalidIdentifierError, /Invalid database\/user identifier/)
    end

    it 'returns the identifier for valid names' do
      expect(described_class.sanitize_identifier('valid_name')).to eq('valid_name')
    end
  end

  describe '.valid_password?' do
    it 'returns true for valid passwords' do
      expect(described_class.valid_password?('password123')).to be true
      expect(described_class.valid_password?('C0mpl3x!P@ss')).to be true
    end

    it 'returns false for nil or empty passwords' do
      expect(described_class.valid_password?(nil)).to be false
      expect(described_class.valid_password?('')).to be false
    end

    it 'returns false for passwords that are too long' do
      expect(described_class.valid_password?('a' * 101)).to be false
    end
  end

  describe '.valid_file_path?' do
    it 'returns true for valid file paths' do
      expect(described_class.valid_file_path?('/tmp/backup.dump')).to be true
      expect(described_class.valid_file_path?('backup.dump')).to be true
    end

    it 'returns false for paths with traversal' do
      expect(described_class.valid_file_path?('../etc/passwd')).to be false
      expect(described_class.valid_file_path?('../../secret')).to be false
    end

    it 'returns false for paths with shell metacharacters' do
      expect(described_class.valid_file_path?('file; rm -rf /')).to be false
      expect(described_class.valid_file_path?('file`whoami`')).to be false
      expect(described_class.valid_file_path?('file$(date)')).to be false
    end
  end
end