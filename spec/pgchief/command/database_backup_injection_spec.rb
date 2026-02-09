# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pgchief::Command::DatabaseBackup do
  describe 'shell injection protection' do
    it 'rejects database names with shell injection attempts' do
      expect { described_class.call('test; rm -rf /') }
        .to raise_error(Pgchief::InvalidIdentifierError)
    end

    it 'rejects database names with backticks' do
      expect { described_class.call('test`whoami`') }
        .to raise_error(Pgchief::InvalidIdentifierError)
    end

    it 'rejects database names with command substitution' do
      expect { described_class.call('test$(whoami)') }
        .to raise_error(Pgchief::InvalidIdentifierError)
    end
  end
end