# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pgchief::Config::S3 do
  before do
    toml_file = File.expand_path("spec/fixtures/config_with_s3.toml")
    Pgchief::Config.load_config!(toml_file)
  end

  it "parses the s3 string" do
    s3_config = described_class.new(Pgchief::Config)

    expect(s3_config.bucket).to eq("bucket")
    expect(s3_config.path).to eq("path/")
  end
end
