# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pgchief::Command::ConfigCreate do
  let(:config_create) { described_class.new }

  describe "#call" do
    let(:temp_dir) { __dir__ }

    after do
      FileUtils.rm("#{temp_dir}/config.toml")
    end

    context "when the configuration file does not exist" do
      it "creates the configuration file and outputs a message" do
        expected_output = "Configuration file created at #{temp_dir}/config.toml\n"

        expect { config_create.call(dir: temp_dir) }.to output(expected_output).to_stdout
        expect(File.exist?("#{temp_dir}/config.toml")).to be true
      end
    end

    context "when the configuration file exists" do
      it "does not create the configuration file" do
        FileUtils.touch("#{temp_dir}/config.toml")

        expect(config_create.call(dir: temp_dir)).to be_nil
      end
    end
  end
end
