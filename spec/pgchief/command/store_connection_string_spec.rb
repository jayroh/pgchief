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
      FileUtils.rm_f(CredentialsFile::NAME)
      Pgchief::Config.credentials_file = nil
    end

    it "stores connection string with username as the key" do
      encrypted_key = "username".encrypt("secret")
      encrypted_connection_string = "connection_string".encrypt("secret")

      described_class.call("username", "connection_string", "secret")
      result = CredentialsFile.has?("#{encrypted_key}:#{encrypted_connection_string}")

      expect(result).to be_truthy
    end

    it "stores connection string with the username and database" do
      encrypted_key = "username:database".encrypt("secret")
      encrypted_connection_string = "connection_string".encrypt("secret")

      described_class.call("username:database", "connection_string", "secret")
      result = CredentialsFile.has?("#{encrypted_key}:#{encrypted_connection_string}")

      expect(result).to be_truthy
    end

    it "returns early if the secret is nil" do
      allow(File).to receive(:open)
      key = "username"

      result = described_class.call(key, "connection_string", nil)

      expect(result).to be_nil
      expect(File).not_to have_received(:open)
    end
  end
end
