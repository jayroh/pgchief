# frozen_string_literal: true

RSpec.describe Pgchief::Command::UserCreate do
  around do |example|
    example.run
    delete_user!
  end

  let(:username) { 'test_user' }
  let(:password) { 'test_password' }
  let(:connection_string) { "postgresql://#{username}:#{password}@localhost:5432/" }

  describe '.call' do
    it 'creates a user' do
      allow(Pgchief::Command::StoreConnectionString).to receive(:call).with(connection_string)
      result = described_class.call(username, password)

      expect(result).to eq("User '#{username}' created successfully!")
      expect(users).to include(username)
      expect(Pgchief::Command::StoreConnectionString).to have_received(:call).with(connection_string)
    end

    it 'raises error if a user already exists and stores connection string only once' do
      allow(Pgchief::Command::StoreConnectionString).to receive(:call).with(connection_string)

      described_class.call(username, password)

      expect do
        described_class.call(username, password)
      end.to raise_error(Pgchief::Errors::UserExistsError)

      expect(Pgchief::Command::StoreConnectionString).to have_received(:call).with(connection_string).once
    end
  end

  def users
    @users ||= conn.exec('SELECT usename FROM pg_user').map { |row| row['usename'] }
  end

  def delete_user!
    conn.exec("DROP USER IF EXISTS #{username}")
  end

  def conn
    @conn ||= PG.connect(Pgchief::Config.pgurl)
  end
end
