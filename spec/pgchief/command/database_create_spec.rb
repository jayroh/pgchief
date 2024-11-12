# frozen_string_literal: true

RSpec.describe Pgchief::Command::DatabaseCreate do
  around do |example|
    example.run
    delete_database!
  end

  let(:database) { "test_db" }

  describe ".call" do
    it "creates a new database" do
      result = described_class.call(database)

      expect(result).to eq("Database '#{database}' created successfully!")
      expect(databases).to include(database)
    end

    it "raises error if a database already exists" do
      described_class.call(database)

      expect do
        described_class.call(database)
      end.to raise_error(Pgchief::Errors::DatabaseExistsError)
    end
  end

  def databases
    @databases ||= conn
                   .exec("SELECT datname FROM pg_database")
                   .map { |row| row["datname"] }
  end

  def delete_database!
    conn.exec("DROP DATABASE IF EXISTS #{database}")
  end

  def conn
    @conn ||= PG.connect(Pgchief::Config.pgurl)
  end
end
