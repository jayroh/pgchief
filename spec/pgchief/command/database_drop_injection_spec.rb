# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pgchief::Command::DatabaseDrop do
  describe 'SQL injection protection' do
    it 'rejects database names with SQL injection attempts' do
      expect { described_class.call("test'; DROP DATABASE postgres--") }
        .to raise_error(Pgchief::InvalidIdentifierError)
    end

    it 'rejects database names with special characters' do
      expect { described_class.call('test@database') }
        .to raise_error(Pgchief::InvalidIdentifierError)
    end

    it 'accepts valid database names' do
      expect { described_class.call('valid_test_db') }
        .not_to raise_error(Pgchief::InvalidIdentifierError)
    end
  end
end