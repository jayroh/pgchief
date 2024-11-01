# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pgchief::ConnectionString do
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

    expect(connection_string.username).to eq "postgres"
    expect(connection_string.password).to eq nil
    expect(connection_string.host).to eq "localhost"
    expect(connection_string.port).to eq "5432"
    expect(connection_string.database).to eq nil
  end
end
