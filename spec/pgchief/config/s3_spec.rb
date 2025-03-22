# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pgchief::Config::S3 do
  before do
    toml_file = File.expand_path("spec/fixtures/config_with_s3.toml")
    Pgchief::Config.load_config!({}, toml_file)
  end

  it "parses the s3 string" do
    s3_config = described_class.new(Pgchief::Config)

    expect(s3_config.bucket).to eq("bucket")
    expect(s3_config.path).to eq("path/")
  end

  it "extracts a path with depth > 1" do
    Pgchief::Config.s3_objects_path = "s3://bucket/path/with-dashes/"

    s3_config = described_class.new(Pgchief::Config)

    expect(s3_config.path).to eq("path/with-dashes/")
  end

  it "is backwards compatible with s3_path_prefix" do
    toml_file = File.expand_path("spec/fixtures/config_with_old_path_config.toml")
    Pgchief::Config.load_config!({}, toml_file)

    s3_config = described_class.new(Pgchief::Config)

    expect(s3_config.path).to eq("path/")
  end
end
