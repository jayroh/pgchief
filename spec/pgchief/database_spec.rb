# frozen_string_literal: true

RSpec.describe Pgchief::Database do
  describe ".all" do
    it "returns a list of all databases" do
      Pgchief::Command::DatabaseCreate.call("pgchief1")
      Pgchief::Command::DatabaseCreate.call("pgchief2")

      expect(described_class.all).to include("pgchief1", "pgchief2")

      Pgchief::Command::DatabaseDrop.call("pgchief1")
      Pgchief::Command::DatabaseDrop.call("pgchief2")
    end

    it "does not include 'postgres'" do
      expect(described_class.all).not_to include("postgres")
    end
  end
end
