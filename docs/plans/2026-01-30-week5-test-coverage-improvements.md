# Week 5: Improve Test Coverage to 80%+ Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Increase test coverage from ~54% to 80%+ by adding unit tests for untested classes, improving test isolation with mocks, and adding edge case coverage.

**Architecture:** Add missing tests for all commands and prompts, mock database connections for unit tests, separate integration tests from unit tests, add edge case and error path coverage.

**Tech Stack:** Ruby 3.0+, RSpec, rspec-mocks, test-double patterns

---

## Task 1: Audit Current Coverage

**Step 1: Generate coverage report**

Run: `COVERAGE=true bundle exec rspec`

**Step 2: Identify uncovered files**

Run: `open coverage/index.html`

Review and list files with < 70% coverage. Expected gaps:
- `lib/pgchief/command/database_privileges_grant.rb`
- `lib/pgchief/command/s3_upload.rb`
- `lib/pgchief/prompt/*.rb` (most prompt classes)
- Error paths in many command classes

**Step 3: Create coverage improvement tracking**

Create issue or document listing:
- Current coverage: ~54%
- Target coverage: 80%
- Files needing tests (list from coverage report)
- Priority order (critical business logic first)

**Step 4: Commit coverage baseline**

```bash
# Save baseline for comparison
cp coverage/.last_run.json coverage/baseline.json
git add coverage/baseline.json
git commit -m "test: establish coverage baseline for improvement tracking"
```

---

## Task 2: Add Tests for S3Upload Command

**Files:**
- Create: `spec/pgchief/command/s3_upload_spec.rb`

**Step 1: Write comprehensive tests**

Create `spec/pgchief/command/s3_upload_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/command/s3_upload'
require 'aws-sdk-s3'

RSpec.describe Pgchief::Command::S3Upload do
  let(:local_file) { '/tmp/test_backup.dump' }
  let(:s3_key) { 'backups/test_backup.dump' }
  let(:s3_client) { instance_double(Aws::S3::Client) }
  let(:s3_resource) { instance_double(Aws::S3::Resource) }
  let(:s3_bucket) { instance_double(Aws::S3::Bucket) }
  let(:s3_object) { instance_double(Aws::S3::Object) }

  before do
    allow(Aws::S3::Resource).to receive(:new).and_return(s3_resource)
    allow(s3_resource).to receive(:bucket).and_return(s3_bucket)
    allow(s3_bucket).to receive(:object).and_return(s3_object)

    # Create temp file for testing
    File.write(local_file, 'test backup data')
  end

  after do
    File.delete(local_file) if File.exist?(local_file)
  end

  describe '#upload!' do
    it 'uploads file to S3' do
      expect(s3_object).to receive(:upload_file).with(local_file)

      command = described_class.new(local_file: local_file, s3_key: s3_key)
      command.upload!
    end

    it 'raises error when local file does not exist' do
      expect do
        described_class.new(local_file: '/nonexistent/file', s3_key: s3_key).upload!
      end.to raise_error(Pgchief::BackupError, /File not found/)
    end

    it 'raises error when S3 upload fails' do
      allow(s3_object).to receive(:upload_file).and_raise(Aws::S3::Errors::ServiceError.new(nil, 'upload failed'))

      command = described_class.new(local_file: local_file, s3_key: s3_key)
      expect { command.upload! }.to raise_error(Pgchief::BackupError, /S3 upload failed/)
    end

    it 'validates S3 key format' do
      expect do
        described_class.new(local_file: local_file, s3_key: '../../../etc/passwd')
      end.to raise_error(Pgchief::ValidationError)
    end
  end
end
```

**Step 2: Run tests to see failures**

Run: `bundle exec rspec spec/pgchief/command/s3_upload_spec.rb`
Expected: Tests may fail if s3_upload doesn't have proper error handling

**Step 3: Update S3Upload to match test expectations**

Modify `lib/pgchief/command/s3_upload.rb` to add error handling, validation, etc.

**Step 4: Run tests until they pass**

Run: `bundle exec rspec spec/pgchief/command/s3_upload_spec.rb`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add spec/pgchief/command/s3_upload_spec.rb lib/pgchief/command/s3_upload.rb
git commit -m "test: add comprehensive tests for S3Upload command

- Test successful upload
- Test error cases (missing file, S3 failures)
- Test input validation
- Mock S3 client to avoid real AWS calls"
```

---

## Task 3: Add Tests for Prompt Classes

**Files:**
- Create: `spec/pgchief/prompt/start_spec.rb`
- Create: `spec/pgchief/prompt/database_management_spec.rb`
- Create: `spec/pgchief/prompt/user_management_spec.rb`

**Step 1: Write tests for Start prompt**

Create `spec/pgchief/prompt/start_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/prompt/start'

RSpec.describe Pgchief::Prompt::Start do
  let(:prompt) { instance_double(TTY::Prompt) }
  let(:start_prompt) { described_class.new(prompt: prompt) }

  describe '#start!' do
    it 'presents main menu options' do
      expect(prompt).to receive(:select).with(
        'What would you like to do?',
        anything
      ).and_return('Database Management')

      # Mock subsequent prompt
      allow_any_instance_of(Pgchief::Prompt::DatabaseManagement).to receive(:start!)

      start_prompt.start!
    end

    it 'navigates to Database Management' do
      allow(prompt).to receive(:select).and_return('Database Management')

      db_management = instance_double(Pgchief::Prompt::DatabaseManagement)
      expect(Pgchief::Prompt::DatabaseManagement).to receive(:new).and_return(db_management)
      expect(db_management).to receive(:start!)

      start_prompt.start!
    end

    it 'navigates to User Management' do
      allow(prompt).to receive(:select).and_return('User Management')

      user_management = instance_double(Pgchief::Prompt::UserManagement)
      expect(Pgchief::Prompt::UserManagement).to receive(:new).and_return(user_management)
      expect(user_management).to receive(:start!)

      start_prompt.start!
    end

    it 'exits when user selects exit' do
      allow(prompt).to receive(:select).and_return('Exit')

      expect { start_prompt.start! }.to raise_error(SystemExit)
    end
  end
end
```

**Step 2: Write tests for DatabaseManagement prompt**

Create `spec/pgchief/prompt/database_management_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/prompt/database_management'

RSpec.describe Pgchief::Prompt::DatabaseManagement do
  let(:prompt) { instance_double(TTY::Prompt) }
  let(:db_prompt) { described_class.new(prompt: prompt) }

  describe '#start!' do
    it 'presents database management options' do
      expect(prompt).to receive(:select).with(
        'Database Management',
        anything
      ).and_return('Back')

      db_prompt.start!
    end

    it 'creates database when selected' do
      allow(prompt).to receive(:select).and_return('Create Database')
      allow(prompt).to receive(:ask).and_return('testdb')

      create_command = instance_double(Pgchief::Command::DatabaseCreate)
      expect(Pgchief::Command::DatabaseCreate).to receive(:new)
        .with(database: 'testdb')
        .and_return(create_command)
      expect(create_command).to receive(:create_db!)

      # Mock return to menu
      allow(prompt).to receive(:select).and_return('Back')

      db_prompt.start!
    end

    it 'drops database when selected' do
      allow(prompt).to receive(:select).and_return('Drop Database', 'Back')
      allow(prompt).to receive(:ask).and_return('testdb')

      drop_command = instance_double(Pgchief::Command::DatabaseDrop)
      expect(Pgchief::Command::DatabaseDrop).to receive(:new)
        .with(database: 'testdb')
        .and_return(drop_command)
      expect(drop_command).to receive(:drop_db!)

      db_prompt.start!
    end
  end
end
```

**Step 3: Run prompt tests**

Run: `bundle exec rspec spec/pgchief/prompt/ -v`
Expected: Tests pass with mocked TTY::Prompt

**Step 4: Commit**

```bash
git add spec/pgchief/prompt/
git commit -m "test: add tests for prompt classes

- Test Start prompt navigation
- Test DatabaseManagement prompt options
- Test UserManagement prompt options
- Mock TTY::Prompt to avoid interactive input"
```

---

## Task 4: Add Error Path Coverage

**Files:**
- Modify: All command spec files to add error cases

**Step 1: Add error tests to DatabaseCreate**

Modify `spec/pgchief/command/database_create_spec.rb`:

```ruby
# Add these tests

describe 'error handling' do
  it 'raises ConnectionError when cannot connect' do
    allow(PG).to receive(:connect).and_raise(PG::ConnectionBad, 'connection refused')

    expect { described_class.new(database: 'test') }
      .to raise_error(Pgchief::ConnectionError, /Failed to connect/)
  end

  it 'raises DatabaseError when database already exists' do
    allow_any_instance_of(PG::Connection).to receive(:exec)
      .and_raise(PG::DuplicateDatabase, 'database "test" already exists')

    expect { described_class.new(database: 'test').create_db! }
      .to raise_error(Pgchief::DatabaseError)
  end

  it 'raises PermissionError when insufficient privileges' do
    allow_any_instance_of(PG::Connection).to receive(:exec)
      .and_raise(PG::InsufficientPrivilege, 'permission denied')

    expect { described_class.new(database: 'test').create_db! }
      .to raise_error(Pgchief::PermissionError)
  end

  it 'closes connection even when error occurs' do
    conn = instance_double(PG::Connection)
    allow(PG).to receive(:connect).and_return(conn)
    allow(conn).to receive(:exec).and_raise(PG::Error)
    expect(conn).to receive(:close)

    expect { described_class.new(database: 'test').create_db! }
      .to raise_error(Pgchief::DatabaseError)
  end
end
```

**Step 2: Add error tests to all command classes**

Repeat similar error testing patterns for:
- DatabaseDrop
- UserCreate
- UserDrop
- DatabaseBackup
- DatabaseRestore
- DatabasePrivilegesGrant
- DatabasePrivilegesRevoke

**Step 3: Run tests**

Run: `COVERAGE=true bundle exec rspec spec/pgchief/command/`
Expected: Coverage improves for command classes

**Step 4: Commit**

```bash
git add spec/pgchief/command/
git commit -m "test: add error path coverage for all commands

- Test connection failures
- Test permission errors
- Test resource conflicts (duplicate database, etc.)
- Test connection cleanup in error scenarios
- Increase command coverage to 80%+"
```

---

## Task 5: Add Mock-Based Unit Tests

**Files:**
- Create: `spec/support/pg_connection_helper.rb`

**Step 1: Create mock helper**

Create `spec/support/pg_connection_helper.rb`:

```ruby
# frozen_string_literal: true

module PgConnectionHelper
  def mock_pg_connection
    instance_double(PG::Connection).tap do |conn|
      allow(conn).to receive(:exec).and_return(true)
      allow(conn).to receive(:exec_params).and_return(true)
      allow(conn).to receive(:close)
      allow(conn).to receive(:finished?).and_return(false)
    end
  end

  def stub_pg_connect(connection = mock_pg_connection)
    allow(PG).to receive(:connect).and_return(connection)
    connection
  end
end

RSpec.configure do |config|
  config.include PgConnectionHelper
end
```

**Step 2: Refactor existing tests to use mocks**

Update existing command tests to use mocks instead of real DB connections:

```ruby
# Before:
describe Pgchief::Command::DatabaseCreate do
  it 'creates a database' do
    command = described_class.new(database: 'testdb')
    # Uses real database connection
  end
end

# After:
describe Pgchief::Command::DatabaseCreate do
  it 'creates a database' do
    conn = stub_pg_connect
    expect(conn).to receive(:exec).with('CREATE DATABASE testdb')
    expect(conn).to receive(:exec).with('REVOKE CONNECT ON DATABASE testdb FROM PUBLIC')

    command = described_class.new(database: 'testdb')
    command.create_db!
  end
end
```

**Step 3: Tag integration tests separately**

Add `:integration` tag to tests that actually connect to database:

```ruby
RSpec.describe 'Database Operations', :integration do
  # Real database tests
end
```

**Step 4: Update spec_helper to skip integration tests by default**

Modify `spec/spec_helper.rb`:

```ruby
RSpec.configure do |config|
  # Skip integration tests by default (run with --tag integration)
  config.filter_run_excluding :integration unless ENV['INTEGRATION']
end
```

**Step 5: Run unit tests only**

Run: `bundle exec rspec --tag ~integration`
Expected: Fast unit tests with mocks, no database required

**Step 6: Commit**

```bash
git add spec/support/pg_connection_helper.rb spec/spec_helper.rb spec/pgchief/command/
git commit -m "test: add mock-based unit tests

- Create PG connection mock helper
- Refactor tests to use mocks for unit testing
- Tag integration tests separately
- Unit tests run without database connection
- Improves test speed and isolation"
```

---

## Task 6: Add Edge Case Coverage

**Files:**
- Create: `spec/pgchief/edge_cases_spec.rb`

**Step 1: Write edge case tests**

Create `spec/pgchief/edge_cases_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Edge Cases' do
  describe 'identifier validation edge cases' do
    it 'handles empty strings' do
      expect(Pgchief::Validators.valid_identifier?('')).to be false
    end

    it 'handles nil values' do
      expect(Pgchief::Validators.valid_identifier?(nil)).to be false
    end

    it 'handles whitespace-only strings' do
      expect(Pgchief::Validators.valid_identifier?('   ')).to be false
    end

    it 'handles identifiers exactly at length limit' do
      exactly_63 = 'a' * 63
      expect(Pgchief::Validators.valid_identifier?(exactly_63)).to be true
    end

    it 'handles identifiers just over length limit' do
      sixty_four = 'a' * 64
      expect(Pgchief::Validators.valid_identifier?(sixty_four)).to be false
    end

    it 'handles identifiers starting with underscore' do
      expect(Pgchief::Validators.valid_identifier?('_test')).to be true
    end

    it 'handles identifiers starting with number' do
      expect(Pgchief::Validators.valid_identifier?('1test')).to be false
    end
  end

  describe 'connection string parsing edge cases' do
    it 'handles URLs with no password' do
      cs = Pgchief::ConnectionString.new('postgresql://user@localhost/db')
      expect(cs.user).to eq('user')
      expect(cs.password).to be_nil
    end

    it 'handles URLs with no user' do
      cs = Pgchief::ConnectionString.new('postgresql://localhost/db')
      expect(cs.user).to be_nil
    end

    it 'handles URLs with port numbers' do
      cs = Pgchief::ConnectionString.new('postgresql://localhost:5433/db')
      expect(cs.port).to eq(5433)
    end

    it 'handles URLs with URL-encoded passwords' do
      cs = Pgchief::ConnectionString.new('postgresql://user:p%40ssword@localhost/db')
      expect(cs.password).to include('@')
    end
  end

  describe 'file path edge cases' do
    it 'handles paths with spaces' do
      expect(Pgchief::Validators.valid_file_path?('/tmp/my backup.dump')).to be true
    end

    it 'handles relative paths' do
      expect(Pgchief::Validators.valid_file_path?('backup.dump')).to be true
    end

    it 'handles home directory expansion' do
      path = '~/backups/db.dump'
      sanitized = Pgchief::Validators.sanitize_file_path(path)
      expect(sanitized).not_to include('~')
    end
  end

  describe 'configuration edge cases' do
    it 'handles missing config file gracefully' do
      allow(File).to receive(:exist?).and_return(false)
      expect { Pgchief::Config.load_config! }.not_to raise_error
    end

    it 'handles malformed TOML config' do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).and_return('invalid toml {{{{')
      expect { Pgchief::Config.load_config! }.not_to raise_error
    end
  end
end
```

**Step 2: Run edge case tests**

Run: `bundle exec rspec spec/pgchief/edge_cases_spec.rb`
Expected: Some tests may fail, revealing edge case bugs

**Step 3: Fix edge cases found**

Update code to handle edge cases properly.

**Step 4: Commit**

```bash
git add spec/pgchief/edge_cases_spec.rb
git commit -m "test: add edge case coverage

- Test empty/nil identifier handling
- Test length boundary conditions
- Test connection string parsing edge cases
- Test file path special characters
- Test configuration error handling"
```

---

## Task 7: Check Coverage and Fill Gaps

**Step 1: Run full test suite with coverage**

Run: `COVERAGE=true bundle exec rspec`

**Step 2: Review coverage report**

Run: `open coverage/index.html`

Identify any files still below 70% coverage.

**Step 3: Add tests for gaps**

For each uncovered file/class:
1. Write tests for uncovered lines
2. Run tests
3. Verify coverage improves
4. Commit

**Step 4: Repeat until 80%+ coverage**

Continue adding tests until:
- Overall coverage >= 80%
- No individual file < 70% (except vendored code)

---

## Verification Checklist

- [ ] Coverage report generated
- [ ] S3Upload has comprehensive tests
- [ ] All prompt classes have tests
- [ ] Error paths tested for all commands
- [ ] Mock-based unit tests for fast execution
- [ ] Integration tests tagged separately
- [ ] Edge cases covered
- [ ] Overall coverage >= 80%
- [ ] No critical files < 70% coverage
- [ ] All tests passing

## Notes

- Target is 80% overall, 70% minimum per file
- Use mocks for unit tests (fast, no DB required)
- Use integration tests for end-to-end verification
- Edge cases often reveal bugs - fix them!
- Focus on critical business logic first
