# frozen_string_literal: true

require 'spec_helper'

class CredentialsFile
  NAME = 'credentials_file'

  def self.has?(line)
    new.has?(line)
  end

  attr_reader :file

  def initialize
    @file = File.read(CredentialsFile::NAME)
  end

  def has?(line)
    file.include? line
  end
end

RSpec.describe Pgchief::Command::StoreConnectionString do
  describe '#call' do
    around do |example|
      Pgchief::Config.credentials_file = CredentialsFile::NAME
      example.run
      FileUtils.rm_f(CredentialsFile::NAME)
      Pgchief::Config.credentials_file = nil
    end

    it 'stores connection string' do
      connection_string = 'postgresql://username:pass@localhost:5432'

      described_class.call(connection_string)
      result = CredentialsFile.has?(connection_string)

      expect(result).to be_truthy
    end
  end
end
