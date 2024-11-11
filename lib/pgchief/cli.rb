# frozen_string_literal: true

module Pgchief
  # Command line interface and option parsing
  class Cli
    include TTY::Option

    option :init do
      short "-i"
      long "--init"
      desc "Initialize the TOML configuration file"
    end

    def run
      if params[:init]
        Pgchief::Command::ConfigCreate.call
      else
        Pgchief::Prompt::Start.call
      end
    end
  end
end
