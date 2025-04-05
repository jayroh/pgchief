# frozen_string_literal: true

module Pgchief
  # Command line interface and option parsing
  class Cli
    include TTY::Option

    banner 'Usage: pgchief [OPTIONS]'

    option :init do
      short '-i'
      long '--init'
      desc 'Initialize the TOML configuration file.'
    end

    option :version do
      short '-v'
      long '--version'
      desc 'Show the version.'
    end

    option :'remote-restore' do
      long '--remote-restore'
      desc 'Restore a database from a remote backup.'
    end

    option :'remote-backup' do
      long '--remote-backup'
      desc 'Backup a database to a remote location.'
    end

    option :restore do
      short '-r'
      long '--restore string'
      arity 1
      desc 'Quickly restore specific database. Pass name of db.'
    end

    flag :help do
      short '-h'
      long '--help'
      desc 'Print usage.'
    end

    def run # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      if params[:help]
        print help
      elsif params[:init]
        Pgchief::Command::ConfigCreate.call
      elsif params[:version]
        puts Pgchief::VERSION
      elsif params[:restore]
        puts Pgchief::Command::QuickRestore.call(params, params[:restore])
      else
        Pgchief::Prompt::Start.call(params)
      end
    rescue Pgchief::Error => e
      puts e.message
    end
  end
end
