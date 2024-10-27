# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pgchief::Command::RetrieveConnectionString do
  describe "#call" do
    around do |example|
      Pgchief::Config.credentials_file = "credentials_file"
      example.run
      File.delete("credentials_file")
      Pgchief::Config.credentials_file = nil
    end

    it "returns connection string for the user and database" do
      encrypted_username_and_db = "username:database".encrypt("password")
      encrypted_connection_string = "connection_string".encrypt("password")

      File.write(
        Pgchief::Config.credentials_file,
        "#{encrypted_username_and_db}:#{encrypted_connection_string}"
      )

      result = described_class.call("username", "password", "database")

      expect(result).to eq("connection_string")
    end

    it "returns connection string for the user" do
      encrypted_username = "username".encrypt("password")
      encrypted_connection_string = "connection_string".encrypt("password")

      File.write(
        Pgchief::Config.credentials_file,
        "#{encrypted_username}:#{encrypted_connection_string}"
      )

      result = described_class.call("username", "password")

      expect(result).to eq("connection_string")
    end

    context "when encrypted line is nil" do
      it "returns nil" do
        File.write(Pgchief::Config.credentials_file, "")

        result = described_class.call("username", "password", "database")

        expect(result).to eq "No connection string found"
      end
    end
  end
end