# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pgchief::Prompt::GrantDatabasePrivileges do
  it "calls the command to grant database privileges" do
    username = "username"
    password = "password"
    databases = %w[database1 database2]

    allow(Pgchief::Command::DatabasePrivilegesGrant)
      .to receive(:call)
      .with(username, password, databases)

    described_class.call("username", "password", %w[database1 database2])

    expect(Pgchief::Command::DatabasePrivilegesGrant).to have_received(:call).with(username, password, databases)
  end
end
