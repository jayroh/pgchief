# frozen_string_literal: true

require "spec_helper"

class CredentialsFile
  NAME = "credentials_file"

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
  describe "#call" do
    around do |example|
      Pgchief::Config.credentials_file = CredentialsFile::NAME
      example.run
      File.delete(CredentialsFile::NAME)
      Pgchief::Config.credentials_file = nil
    end

    it "stores connection string with just the username" do
      encrypted_username = "username".encrypt("secret")
      encrypted_connection_string = "connection_string".encrypt("secret")

      described_class.call("username", "connection_string", "secret")
      result = CredentialsFile.has?("#{encrypted_username}:#{encrypted_connection_string}")

      expect(result).to be_truthy
    end

    it "stores connection string with the username and database" do
      encrypted_username_and_database = "username:database".encrypt("secret")
      encrypted_connection_string = "connection_string".encrypt("secret")

      described_class.call("username", "connection_string", "secret", "database")
      result = CredentialsFile.has?("#{encrypted_username_and_database}:#{encrypted_connection_string}")

      expect(result).to be_truthy
    end
  end
end
