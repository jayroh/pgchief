# frozen_string_literal: true

require 'spec_helper'
require 'pry'

RSpec.describe Pgchief::Credentials do
  around do |example|
    Pgchief::Config.credentials_file = File.join(__dir__, '..', '..', 'tmp', 'pgchief_credentials')
    FileUtils.touch(Pgchief::Config.credentials_file)

    example.run

    FileUtils.rm(Pgchief::Config.credentials_file)
  end

  context 'when the password is valid' do
    let(:credentials_file) { File.read(Pgchief::Config.credentials_file) }

    it 'encrypts username:password' do
      described_class.encrypt('username:password', 'secret')

      expect(credentials_file).not_to be_empty
      expect(credentials_file).not_to include('username:password')
    end

    # it 'decrypts username:password with correct secret' do
    #   described_class.encrypt('john:secret123', 'secret')
    #
    #   decrypted = described_class.decrypt(username: 'john', 'secret')
    #
    #   expect(decrypted).to eq('john:secret123')
    # end
  end
end
