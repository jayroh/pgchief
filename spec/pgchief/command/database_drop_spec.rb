# frozen_string_literal: true

RSpec.describe Pgchief::Command::DatabaseDrop do
  let(:database) { 'test_db' }

  describe '.call' do
    context 'when the database exists' do
      it 'drops an existing database' do
        create_database!

        result = described_class.call(database)

        expect(result).to eq("Database '#{database}' dropped successfully!")
        expect(databases).not_to include(database)
      end

      it 'reports that the database does not exist' do
        result = described_class.call(database)

        expect(result).to eq("Database '#{database}' does not exist.")
        expect(databases).not_to include(database)
      end
    end
  end

  def create_database!
    Pgchief::Command::DatabaseCreate.call(database)
  end

  def databases
    @databases ||= conn
                   .exec('SELECT datname FROM pg_database')
                   .map { |row| row['datname'] }
  end

  def conn
    @conn ||= PG.connect(Pgchief::Config.pgurl)
  end
end
