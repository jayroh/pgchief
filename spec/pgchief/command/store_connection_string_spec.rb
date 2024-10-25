# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pgchief::Command::StoreConnectionString do
  CREDENTIALS_FILE = "credentials_file"

  describe "#call" do
    around do |example|
      Pgchief::Config.credentials_file = CREDENTIALS_FILE
      example.run
      File.delete(CREDENTIALS_FILE)
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

  class CredentialsFile
    def self.has?(line)
      new.has?(line)
    end

    def initialize
      @file = File.read(CREDENTIALS_FILE)
    end

    def has?(line)
      @file.include? line
    end
  end
end
