# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pgchief::Config do
  around do |example|
    original_env        = ENV.fetch("DATABASE_URL", nil)
    ENV["DATABASE_URL"] = nil

    example.run

    ENV["DATABASE_URL"] = original_env
  end

  it "prints out an error if the config file does not exist" do
    toml_file = "non_existent_file.toml"
    expected_first = "You must create a config file at #{toml_file}."
    expected_second = "run `pgchief --init` to create it."
    expected_regex = /#{expected_first}.*#{expected_second}/m

    expect { described_class.load_config!(toml_file) }
      .to output(expected_regex).to_stdout
  end

  it "allows setting and getting of configuration settings" do
    described_class.credentials_file = "credentials_file"
    described_class.pgurl = "postgresql://localhost:5432"
    described_class.backup_dir = "/tmp"

    expect(described_class.credentials_file).to eq("credentials_file")
    expect(described_class.pgurl).to eq("postgresql://localhost:5432")
    expect(described_class.backup_dir).to eq("/tmp")
  end

  it "loads default configuration settings from a TOML file" do
    toml_file = File.expand_path("spec/fixtures/config_default.toml")

    described_class.load_config!(toml_file)

    expect(described_class.pgurl).to eq("postgresql://localhost:5432")
    expect(described_class.backup_dir).to eq("/tmp")
    expect(described_class.credentials_file).to be_nil
  end

  it "loads different configuration settings from a TOML file" do
    toml_file = File.expand_path("spec/fixtures/config_with_credentials_file.toml")

    described_class.load_config!(toml_file)

    expect(described_class.pgurl).to eq("postgresql://localhost:5432")
    expect(described_class.backup_dir).to eq("/tmp/backups")
    expect(described_class.credentials_file).to eq("#{Dir.home}/creds")
  end
end
