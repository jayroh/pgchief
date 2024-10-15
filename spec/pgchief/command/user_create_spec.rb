# frozen_string_literal: true

RSpec.describe Pgchief::Command::UserCreate do
  around do |example|
    example.run
    delete_user!
  end

  let(:username) { "test_user" }
  let(:password) { "test_password" }

  describe ".call" do
    it "creates a user" do
      result = described_class.call(username, password)

      expect(result).to eq("User '#{username}' created successfully!")
      expect(users).to include(username)
    end

    it "raises error if a user already exists" do
      described_class.call(username, password)

      expect do
        described_class.call(username, password)
      end.to raise_error(Pgchief::Errors::UserExistsError)
    end
  end

  def users
    @users ||= conn.exec("SELECT usename FROM pg_user").map { |row| row["usename"] }
  end

  def delete_user!
    conn.exec("DROP USER IF EXISTS #{username}")
  end

  def conn
    @conn ||= PG.connect(Pgchief::DATABASE_URL)
  end
end
