# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pgchief::Prompt::RestoreDatabase do
  let(:prompt_double) { instance_double(TTY::Prompt) }
  let(:databases) { %w[db1 db2] }
  let(:backup_files) { ['db1-20250325.dump', 'db1-20250324.dump'] }
  let(:selected_database) { 'db1' }
  let(:selected_backup) { 'db1-20250325.dump' }
  let(:restore_result) { "Database 'db1' restored from db1-20250325.dump" }

  before do
    allow(TTY::Prompt).to receive(:new).and_return(prompt_double)
    allow(prompt_double).to receive(:on)
    allow(Pgchief::Database).to receive(:all).and_return(databases)
    allow(Pgchief::Database).to receive(:backups_for).with(
      selected_database,
      remote: Pgchief::Config.remote_restore
    ).and_return(backup_files)
    allow(Pgchief::Command::DatabaseRestore)
      .to receive(:call)
      .with(selected_database, selected_backup)
      .and_return(restore_result)

    # Mock the prompt interactions
    allow(prompt_double).to receive(:select)
      .with('Which database needs restoring?', databases)
      .and_return(selected_database)
    allow(prompt_double).to receive(:select)
      .with('Which backup file do you want to restore?', backup_files)
      .and_return(selected_backup)
    allow(prompt_double).to receive(:say).with(restore_result)
  end

  describe '#call' do
    it 'prompts for database selection' do
      described_class.call

      expect(prompt_double)
        .to have_received(:select)
        .with('Which database needs restoring?', databases)
    end

    it 'prompts for backup file selection' do
      described_class.call

      expect(prompt_double)
        .to have_received(:select)
        .with('Which backup file do you want to restore?', backup_files)
    end

    it 'calls the DatabaseRestore command with selected options' do
      described_class.call

      expect(Pgchief::Command::DatabaseRestore)
        .to have_received(:call)
        .with(selected_database, selected_backup)
    end

    it 'displays the result of the restore operation' do
      described_class.call

      expect(prompt_double).to have_received(:say).with(restore_result)
    end

    context 'when remote restore is enabled' do
      before do
        allow(Pgchief::Config).to receive(:remote_restore).and_return(true)
      end

      it 'fetches remote backup files' do
        allow(Pgchief::Database)
          .to receive(:backups_for)
          .with(selected_database, remote: true)
          .and_return(backup_files)

        described_class.call

        expect(Pgchief::Database)
          .to have_received(:backups_for)
          .with(selected_database, remote: true)
      end

      it 'handles when no remote files are found' do
        allow(Pgchief::Database)
          .to receive(:backups_for)
          .with(selected_database, remote: true)
          .and_return([])

        allow(prompt_double).to receive(:warn).with("No backup files found for database '#{selected_database}'")

        expect { described_class.call }.not_to raise_error
        expect(prompt_double).to have_received(:warn).with("No backup files found for database '#{selected_database}'")
        expect(Pgchief::Command::DatabaseRestore).not_to have_received(:call)
      end
    end

    context 'when remote restore is disabled' do
      it 'fetches local backup files' do
        allow(Pgchief::Config).to receive(:remote_restore).and_return(false)
        allow(Pgchief::Database)
          .to receive(:backups_for)
          .with(selected_database, remote: false)
          .and_return(backup_files)

        described_class.call

        expect(Pgchief::Database)
          .to have_received(:backups_for)
          .with(selected_database, remote: false)
      end
    end
  end
end
