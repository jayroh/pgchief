# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pgchief::Command::RetrieveConnectionString do
  describe "#call" do
    around do |example|
      Pgchief::Config.credentials_file = "credentials_file"
      example.run
      FileUtils.rm_f("credentials_file")
      Pgchief::Config.credentials_file = nil
    end

    it "returns connection string for the user and database" do
      connection_string = "postgresql://username:pass@localhost:5432/database"
      File.write(Pgchief::Config.credentials_file, connection_string)

      result = described_class.call("username", "database")

      expect(result).to eq(connection_string)
    end

    it "returns connection string for the user" do
      connection_string = "postgresql://username:pass@localhost:5432"
      File.write(Pgchief::Config.credentials_file, connection_string)

      result = described_class.call("username")

      expect(result).to eq(connection_string)
    end

    context "when file is empty" do
      it "returns nil" do
        File.write(Pgchief::Config.credentials_file, "")

        result = described_class.call("username", "database")

        expect(result).to eq "No connection string found"
      end
    end
  end
end
