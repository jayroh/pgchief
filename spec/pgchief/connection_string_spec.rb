# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pgchief::ConnectionString do
  context "when assigning attributes from the provided connection string" do
    it "parses a connection string's parts to the correct properties" do
      connection_string = described_class.new("postgres://user:pass@localhost:1234/mydb")

      expect(connection_string.username).to eq "user"
      expect(connection_string.password).to eq "pass"
      expect(connection_string.host).to eq "localhost"
      expect(connection_string.port).to eq "1234"
      expect(connection_string.database).to eq "mydb"
    end

    it "parses a minimal string's parts to the correct properties" do
      connection_string = described_class.new("postgresql://localhost")

      expect(connection_string.username).to eq ""
      expect(connection_string.password).to eq ""
      expect(connection_string.host).to eq "localhost"
      expect(connection_string.port).to eq "5432"
      expect(connection_string.database).to eq ""
    end

    it "parses username and host" do
      connection_string = described_class.new("postgresql://joel@localhost")

      expect(connection_string.username).to eq "joel"
      expect(connection_string.password).to eq ""
      expect(connection_string.host).to eq "localhost"
      expect(connection_string.port).to eq "5432"
      expect(connection_string.database).to eq ""
    end
  end

  context "when overriding properties via initializer" do
    it "overrides host, db, username and password" do
      connection_string = described_class.new(
        "postgres://localhost",
        username: "dbuser",
        password: "dbpass",
        host: "dbhost",
        database: "dbname"
      )

      expect(connection_string.to_s).to eq "postgresql://dbuser:dbpass@dbhost:5432/dbname"
    end
  end

  describe "#.to_s" do
    it "returns the string based on the properties" do
      expect(described_class.new("postgres://user:pass@localhost:1234/mydb").to_s)
        .to eq "postgresql://user:pass@localhost:1234/mydb"

      expect(described_class.new("postgresql://user@localhost").to_s)
        .to eq "postgresql://user:@localhost:5432/"
    end
  end
end
