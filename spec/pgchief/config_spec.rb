# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pgchief::Config do
  it "allows setting and getting of configuration settings" do
    described_class.credentials_file = "credentials_file"
    described_class.credentials_secret = "secret-password"
    described_class.pgurl = "postgresql://localhost:5432"
    described_class.backup_dir = "/tmp"

    expect(described_class.credentials_file).to eq("credentials_file")
    expect(described_class.credentials_secret).to eq("secret-password")
    expect(described_class.pgurl).to eq("postgresql://localhost:5432")
    expect(described_class.backup_dir).to eq("/tmp")
  end

  it "loads default configuration settings from a TOML file" do
    toml_file = File.expand_path("spec/fixtures/config_default.toml")

    described_class.load_config!(toml_file)

    expect(described_class.pgurl).to eq("postgresql://localhost:5432")
    expect(described_class.backup_dir).to eq("/tmp")
    expect(described_class.credentials_file).to eq(nil)
  end

  it "loads different configuration settings from a TOML file" do
    toml_file = File.expand_path("spec/fixtures/config_with_credentials_file.toml")

    described_class.load_config!(toml_file)

    expect(described_class.pgurl).to eq("postgresql://localhost:5432")
    expect(described_class.backup_dir).to eq("/tmp/backups")
    expect(described_class.credentials_file).to eq("~/creds")
  end
end
