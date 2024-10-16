# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pgchief::Command::ConfigCreate do
  let(:config_create) { described_class.new }

  describe "#call" do
    let(:temp_dir) { File.join(__dir__, "..", "..", "..", "tmp") }

    after do
      FileUtils.rm("#{temp_dir}/.pgchief.toml")
    end

    context "when the configuration file does not exist" do
      it "creates the configuration file and outputs a message" do
        expected_output = "Configuration file created at #{temp_dir}/.pgchief.toml\n"

        expect { config_create.call(dir: temp_dir) }.to output(expected_output).to_stdout
        expect(File.exist?("#{temp_dir}/.pgchief.toml")).to be true
      end
    end

    context "when the configuration file exists" do
      it "does not create the configuration file" do
        FileUtils.touch("#{temp_dir}/.pgchief.toml")

        expect(config_create.call(dir: temp_dir)).to be_nil
      end
    end
  end
end
