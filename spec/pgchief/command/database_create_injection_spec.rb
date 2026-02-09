# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pgchief::Command::DatabaseCreate do
  describe 'SQL injection protection' do
    it 'rejects database names with semicolons' do
      expect { described_class.call('test;DROP DATABASE postgres') }
        .to raise_error(Pgchief::Errors::InvalidIdentifierError, /Invalid database/)
    end

    it 'rejects database names with SQL comments' do
      expect { described_class.call('test--comment') }
        .to raise_error(Pgchief::Errors::InvalidIdentifierError)
    end

    it 'rejects database names with quotes' do
      expect { described_class.call("test'OR'1'='1") }
        .to raise_error(Pgchief::Errors::InvalidIdentifierError)
    end

    it 'rejects database names with spaces' do
      expect { described_class.call('test db') }
        .to raise_error(Pgchief::Errors::InvalidIdentifierError)
    end

    it 'accepts valid database names' do
      # This will fail because we haven't implemented validation yet
      expect { described_class.call('valid_test_db') }
        .not_to raise_error(Pgchief::Errors::InvalidIdentifierError)
    end
  end
end