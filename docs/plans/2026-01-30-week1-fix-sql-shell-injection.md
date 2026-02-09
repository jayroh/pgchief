# Week 1: Fix SQL/Shell Injection Vulnerabilities Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Eliminate all SQL and shell injection vulnerabilities in pgchief by implementing parameterized queries and safe command execution.

**Architecture:** Replace all string interpolation in SQL queries with parameterized queries using PG::Connection#exec_params. Replace backtick shell commands with Open3 or shellwords for safe execution. Add input validation layer.

**Tech Stack:** Ruby 3.0+, pg gem, Open3 (stdlib), Shellwords (stdlib)

---

## Task 1: Add Input Validation Module

**Files:**
- Create: `lib/pgchief/validators.rb`
- Create: `spec/pgchief/validators_spec.rb`

**Step 1: Write the failing test**

Create `spec/pgchief/validators_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/validators'

RSpec.describe Pgchief::Validators do
  describe '.valid_identifier?' do
    it 'returns true for valid identifiers' do
      expect(described_class.valid_identifier?('my_database')).to be true
      expect(described_class.valid_identifier?('user123')).to be true
      expect(described_class.valid_identifier?('test_db_2')).to be true
    end

    it 'returns false for identifiers with special characters' do
      expect(described_class.valid_identifier?('my-database')).to be false
      expect(described_class.valid_identifier?('user@123')).to be false
      expect(described_class.valid_identifier?('test;drop')).to be false
    end

    it 'returns false for identifiers with SQL injection attempts' do
      expect(described_class.valid_identifier?("'; DROP TABLE users--")).to be false
      expect(described_class.valid_identifier?('admin" OR "1"="1')).to be false
    end

    it 'returns false for empty or nil identifiers' do
      expect(described_class.valid_identifier?('')).to be false
      expect(described_class.valid_identifier?(nil)).to be false
    end

    it 'returns false for identifiers that are too long' do
      expect(described_class.valid_identifier?('a' * 64)).to be false
    end
  end

  describe '.sanitize_identifier' do
    it 'raises error for invalid identifiers' do
      expect { described_class.sanitize_identifier('bad;name') }
        .to raise_error(Pgchief::InvalidIdentifierError, /Invalid database\/user identifier/)
    end

    it 'returns the identifier for valid names' do
      expect(described_class.sanitize_identifier('valid_name')).to eq('valid_name')
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/pgchief/validators_spec.rb -v`
Expected: FAIL with "uninitialized constant Pgchief::Validators"

**Step 3: Write minimal implementation**

Create `lib/pgchief/validators.rb`:

```ruby
# frozen_string_literal: true

module Pgchief
  class InvalidIdentifierError < StandardError; end

  module Validators
    # PostgreSQL identifier naming rules:
    # - Must start with letter or underscore
    # - Can contain letters, digits, underscores
    # - Max 63 bytes
    IDENTIFIER_REGEX = /\A[a-z_][a-z0-9_]*\z/i
    MAX_IDENTIFIER_LENGTH = 63

    def self.valid_identifier?(identifier)
      return false if identifier.nil? || identifier.empty?
      return false if identifier.length > MAX_IDENTIFIER_LENGTH
      identifier.match?(IDENTIFIER_REGEX)
    end

    def self.sanitize_identifier(identifier)
      unless valid_identifier?(identifier)
        raise InvalidIdentifierError, "Invalid database/user identifier: #{identifier.inspect}"
      end
      identifier
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/pgchief/validators_spec.rb -v`
Expected: All tests PASS

**Step 5: Require validators in main file**

Modify `lib/pgchief.rb` to require validators:

```ruby
# Add after other requires
require_relative 'pgchief/validators'
```

**Step 6: Commit**

```bash
git add lib/pgchief/validators.rb spec/pgchief/validators_spec.rb lib/pgchief.rb
git commit -m "feat: add input validation module for database/user identifiers

- Add Validators module with valid_identifier? and sanitize_identifier
- Protect against SQL injection via identifier validation
- Enforce PostgreSQL naming constraints (63 char max, alphanumeric+underscore)
- Add comprehensive test coverage for edge cases"
```

---

## Task 2: Fix SQL Injection in DatabaseCreate

**Files:**
- Modify: `lib/pgchief/command/database_create.rb:13-15`
- Create: `spec/pgchief/command/database_create_injection_spec.rb`

**Step 1: Write the failing security test**

Create `spec/pgchief/command/database_create_injection_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/command/database_create'
require 'pgchief/validators'

RSpec.describe Pgchief::Command::DatabaseCreate do
  describe 'SQL injection protection' do
    it 'rejects database names with semicolons' do
      expect { described_class.new(database: 'test;DROP DATABASE postgres').create_db! }
        .to raise_error(Pgchief::InvalidIdentifierError, /Invalid database/)
    end

    it 'rejects database names with SQL comments' do
      expect { described_class.new(database: 'test--comment').create_db! }
        .to raise_error(Pgchief::InvalidIdentifierError)
    end

    it 'rejects database names with quotes' do
      expect { described_class.new(database: "test'OR'1'='1").create_db! }
        .to raise_error(Pgchief::InvalidIdentifierError)
    end

    it 'rejects database names with spaces' do
      expect { described_class.new(database: 'test db').create_db! }
        .to raise_error(Pgchief::InvalidIdentifierError)
    end

    it 'accepts valid database names' do
      # This will fail because we haven't implemented validation yet
      expect { described_class.new(database: 'valid_test_db').create_db! }
        .not_to raise_error(Pgchief::InvalidIdentifierError)
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/pgchief/command/database_create_injection_spec.rb -v`
Expected: Tests FAIL - validation not yet implemented, bad names not rejected

**Step 3: Add validation to DatabaseCreate**

Modify `lib/pgchief/command/database_create.rb`:

```ruby
# frozen_string_literal: true

require 'pg'
require_relative 'base'

module Pgchief
  module Command
    class DatabaseCreate < Base
      def initialize(database:)
        @database = Validators.sanitize_identifier(database)  # ADD THIS LINE
        super()
      end

      def create_db!
        conn.exec("CREATE DATABASE #{@database}")
        conn.exec("REVOKE CONNECT ON DATABASE #{@database} FROM PUBLIC")
      rescue PG::Error => e
        puts "Error: #{e.message}"
      ensure
        conn.close
      end

      private

      attr_reader :database
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/pgchief/command/database_create_injection_spec.rb -v`
Expected: All tests PASS

**Step 5: Run existing tests to ensure no regression**

Run: `bundle exec rspec spec/pgchief/command/database_create_spec.rb -v`
Expected: All existing tests still PASS

**Step 6: Commit**

```bash
git add lib/pgchief/command/database_create.rb spec/pgchief/command/database_create_injection_spec.rb
git commit -m "fix: prevent SQL injection in database creation

- Add identifier validation to DatabaseCreate#initialize
- Reject invalid characters before database creation
- Add security tests for SQL injection attempts
- Maintain backward compatibility with valid database names"
```

---

## Task 3: Fix SQL Injection in DatabaseDrop

**Files:**
- Modify: `lib/pgchief/command/database_drop.rb:14`
- Create: `spec/pgchief/command/database_drop_injection_spec.rb`

**Step 1: Write the failing security test**

Create `spec/pgchief/command/database_drop_injection_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/command/database_drop'

RSpec.describe Pgchief::Command::DatabaseDrop do
  describe 'SQL injection protection' do
    it 'rejects database names with SQL injection attempts' do
      expect { described_class.new(database: "test'; DROP DATABASE postgres--").drop_db! }
        .to raise_error(Pgchief::InvalidIdentifierError)
    end

    it 'rejects database names with special characters' do
      expect { described_class.new(database: 'test@database').drop_db! }
        .to raise_error(Pgchief::InvalidIdentifierError)
    end

    it 'accepts valid database names' do
      expect { described_class.new(database: 'valid_test_db').drop_db! }
        .not_to raise_error(Pgchief::InvalidIdentifierError)
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/pgchief/command/database_drop_injection_spec.rb -v`
Expected: FAIL - validation not implemented

**Step 3: Add validation to DatabaseDrop**

Modify `lib/pgchief/command/database_drop.rb`:

```ruby
# frozen_string_literal: true

require 'pg'
require_relative 'base'

module Pgchief
  module Command
    class DatabaseDrop < Base
      def initialize(database:)
        @database = Validators.sanitize_identifier(database)  # ADD THIS LINE
        super()
      end

      def drop_db!
        conn.exec("DROP DATABASE #{@database}")
      rescue PG::Error => e
        puts "Error: #{e.message}"
      ensure
        conn.close
      end

      private

      attr_reader :database
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/pgchief/command/database_drop_injection_spec.rb -v`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/pgchief/command/database_drop.rb spec/pgchief/command/database_drop_injection_spec.rb
git commit -m "fix: prevent SQL injection in database drop

- Add identifier validation to DatabaseDrop#initialize
- Add security tests for SQL injection attempts"
```

---

## Task 4: Fix SQL Injection in UserCreate

**Files:**
- Modify: `lib/pgchief/command/user_create.rb:15,39-41`
- Create: `spec/pgchief/command/user_create_injection_spec.rb`

**Step 1: Write the failing security test**

Create `spec/pgchief/command/user_create_injection_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/command/user_create'

RSpec.describe Pgchief::Command::UserCreate do
  describe 'SQL injection protection' do
    it 'rejects usernames with SQL injection attempts' do
      expect do
        described_class.new(username: "admin'; DROP TABLE users--", password: 'pass123').create_user!
      end.to raise_error(Pgchief::InvalidIdentifierError)
    end

    it 'rejects usernames with special characters' do
      expect do
        described_class.new(username: 'user@domain', password: 'pass123').create_user!
      end.to raise_error(Pgchief::InvalidIdentifierError)
    end

    it 'accepts valid usernames' do
      expect do
        described_class.new(username: 'valid_user', password: 'pass123').create_user!
      end.not_to raise_error(Pgchief::InvalidIdentifierError)
    end

    context 'with role options' do
      it 'rejects role names with SQL injection attempts' do
        expect do
          described_class.new(
            username: 'testuser',
            password: 'pass123',
            role: "admin'; GRANT ALL--"
          ).create_user!
        end.to raise_error(Pgchief::InvalidIdentifierError)
      end
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/pgchief/command/user_create_injection_spec.rb -v`
Expected: FAIL - validation not implemented

**Step 3: Add password validation helper**

Add to `lib/pgchief/validators.rb`:

```ruby
# Add to Pgchief::Validators module

# Password validation - prevent SQL injection via password field
PASSWORD_MAX_LENGTH = 100

def self.valid_password?(password)
  return false if password.nil? || password.empty?
  return false if password.length > PASSWORD_MAX_LENGTH
  # Passwords can contain any characters, but we check length and non-nil
  # The pg gem will properly escape passwords in parameterized queries
  true
end

def self.sanitize_password(password)
  unless valid_password?(password)
    raise InvalidIdentifierError, "Invalid password: must be 1-#{PASSWORD_MAX_LENGTH} characters"
  end
  password
end
```

**Step 4: Add test for password validation**

Add to `spec/pgchief/validators_spec.rb`:

```ruby
describe '.valid_password?' do
  it 'returns true for valid passwords' do
    expect(described_class.valid_password?('password123')).to be true
    expect(described_class.valid_password?('C0mpl3x!P@ss')).to be true
  end

  it 'returns false for nil or empty passwords' do
    expect(described_class.valid_password?(nil)).to be false
    expect(described_class.valid_password?('')).to be false
  end

  it 'returns false for passwords that are too long' do
    expect(described_class.valid_password?('a' * 101)).to be false
  end
end
```

**Step 5: Run validator tests**

Run: `bundle exec rspec spec/pgchief/validators_spec.rb -v`
Expected: All tests PASS

**Step 6: Update UserCreate to use parameterized queries**

Modify `lib/pgchief/command/user_create.rb`:

```ruby
# frozen_string_literal: true

require 'pg'
require_relative 'base'

module Pgchief
  module Command
    class UserCreate < Base
      def initialize(username:, password:, role: nil)
        @username = Validators.sanitize_identifier(username)  # ADD THIS
        @password = Validators.sanitize_password(password)    # ADD THIS
        @role = Validators.sanitize_identifier(role) if role  # ADD THIS
        super()
      end

      def create_user!
        user_options = build_user_options

        # Use parameterized query for password
        # Note: PostgreSQL doesn't support parameters for identifiers (username, role)
        # but we've validated them, so they're safe to interpolate
        sql = "CREATE USER #{@username} WITH #{user_options} PASSWORD $1"
        conn.exec_params(sql, [@password])

        puts "User created: #{@username}"
      rescue PG::Error => e
        puts "Error: #{e.message}"
      ensure
        conn.close if conn && !conn.finished?
      end

      private

      attr_reader :username, :password, :role

      def build_user_options
        options = []
        options << "IN ROLE #{@role}" if @role
        options << 'LOGIN'
        options.join(' ')
      end
    end
  end
end
```

**Step 7: Run tests to verify they pass**

Run: `bundle exec rspec spec/pgchief/command/user_create_injection_spec.rb -v`
Expected: All tests PASS

Run: `bundle exec rspec spec/pgchief/command/user_create_spec.rb -v`
Expected: Existing tests PASS

**Step 8: Commit**

```bash
git add lib/pgchief/validators.rb spec/pgchief/validators_spec.rb lib/pgchief/command/user_create.rb spec/pgchief/command/user_create_injection_spec.rb
git commit -m "fix: prevent SQL injection in user creation

- Add username and password validation
- Use parameterized query for password field
- Validate role names to prevent injection
- Add security tests for user creation"
```

---

## Task 5: Fix SQL Injection in UserDrop

**Files:**
- Modify: `lib/pgchief/command/user_drop.rb:14,26`
- Create: `spec/pgchief/command/user_drop_injection_spec.rb`

**Step 1: Write the failing security test**

Create `spec/pgchief/command/user_drop_injection_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/command/user_drop'

RSpec.describe Pgchief::Command::UserDrop do
  describe 'SQL injection protection' do
    it 'rejects usernames with SQL injection attempts' do
      expect do
        described_class.new(username: "admin'; DROP DATABASE postgres--").drop_user!
      end.to raise_error(Pgchief::InvalidIdentifierError)
    end

    it 'accepts valid usernames' do
      expect do
        described_class.new(username: 'valid_user').drop_user!
      end.not_to raise_error(Pgchief::InvalidIdentifierError)
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/pgchief/command/user_drop_injection_spec.rb -v`
Expected: FAIL

**Step 3: Add validation to UserDrop**

Modify `lib/pgchief/command/user_drop.rb`:

```ruby
# frozen_string_literal: true

require 'pg'
require_relative 'base'

module Pgchief
  module Command
    class UserDrop < Base
      def initialize(username:)
        @username = Validators.sanitize_identifier(username)  # ADD THIS
        super()
      end

      def drop_user!
        if user_exists?
          conn.exec("DROP USER #{@username}")
          puts "User dropped: #{@username}"
        else
          puts "User does not exist: #{@username}"
        end
      rescue PG::Error => e
        puts "Error: #{e.message}"
      ensure
        conn.close if conn && !conn.finished?
      end

      private

      attr_reader :username

      def user_exists?
        # Use parameterized query for existence check
        query = 'SELECT 1 FROM pg_user WHERE usename = $1'
        result = conn.exec_params(query, [@username])
        !result.ntuples.zero?
      end
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/pgchief/command/user_drop_injection_spec.rb -v`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/pgchief/command/user_drop.rb spec/pgchief/command/user_drop_injection_spec.rb
git commit -m "fix: prevent SQL injection in user drop

- Add username validation to UserDrop
- Use parameterized query for user existence check
- Add security tests"
```

---

## Task 6: Fix SQL Injection in DatabasePrivilegesGrant

**Files:**
- Modify: `lib/pgchief/command/database_privileges_grant.rb:15,19-44`
- Create: `spec/pgchief/command/database_privileges_grant_injection_spec.rb`

**Step 1: Write the failing security test**

Create `spec/pgchief/command/database_privileges_grant_injection_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/command/database_privileges_grant'

RSpec.describe Pgchief::Command::DatabasePrivilegesGrant do
  describe 'SQL injection protection' do
    it 'rejects database names with SQL injection attempts' do
      expect do
        described_class.new(
          database: "test'; DROP DATABASE postgres--",
          username: 'testuser'
        ).grant_privs!
      end.to raise_error(Pgchief::InvalidIdentifierError)
    end

    it 'rejects usernames with SQL injection attempts' do
      expect do
        described_class.new(
          database: 'testdb',
          username: "admin'; GRANT ALL--"
        ).grant_privs!
      end.to raise_error(Pgchief::InvalidIdentifierError)
    end

    it 'accepts valid database and username' do
      expect do
        described_class.new(
          database: 'testdb',
          username: 'testuser'
        ).grant_privs!
      end.not_to raise_error(Pgchief::InvalidIdentifierError)
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/pgchief/command/database_privileges_grant_injection_spec.rb -v`
Expected: FAIL

**Step 3: Add validation and refactor DatabasePrivilegesGrant**

Modify `lib/pgchief/command/database_privileges_grant.rb`:

```ruby
# frozen_string_literal: true

require 'pg'
require_relative 'base'

module Pgchief
  module Command
    class DatabasePrivilegesGrant < Base
      GRANT_QUERIES = [
        'GRANT CONNECT ON DATABASE %{database} TO %{username}',
        'GRANT CREATE ON SCHEMA public TO %{username}',
        'GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO %{username}',
        'GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO %{username}',
        'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO %{username}',
        'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO %{username}'
      ].freeze

      def initialize(database:, username:)
        @database = Validators.sanitize_identifier(database)
        @username = Validators.sanitize_identifier(username)
        super()
      end

      def grant_privs!
        # Must connect to the specific database to grant schema privileges
        db_conn = PG.connect(Pgchief::Config.pgurl + "/#{@database}")

        GRANT_QUERIES.each do |query_template|
          query = format(query_template, database: @database, username: @username)
          db_conn.exec(query)
        end

        puts "Privileges granted to #{@username} on #{@database}"
      rescue PG::Error => e
        puts "Error: #{e.message}"
      ensure
        db_conn.close if db_conn && !db_conn.finished?
        conn.close if conn && !conn.finished?
      end

      private

      attr_reader :database, :username
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/pgchief/command/database_privileges_grant_injection_spec.rb -v`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/pgchief/command/database_privileges_grant.rb spec/pgchief/command/database_privileges_grant_injection_spec.rb
git commit -m "fix: prevent SQL injection in privilege grants

- Add validation for database and username
- Refactor repetitive queries into constant array
- Use format instead of interpolation for clarity
- Add security tests
- Fix rubocop violations (method was too long)"
```

---

## Task 7: Fix SQL Injection in DatabasePrivilegesRevoke

**Files:**
- Modify: `lib/pgchief/command/database_privileges_revoke.rb:15,19-44`
- Create: `spec/pgchief/command/database_privileges_revoke_injection_spec.rb`

**Step 1: Write the failing security test**

Create `spec/pgchief/command/database_privileges_revoke_injection_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/command/database_privileges_revoke'

RSpec.describe Pgchief::Command::DatabasePrivilegesRevoke do
  describe 'SQL injection protection' do
    it 'rejects database names with SQL injection attempts' do
      expect do
        described_class.new(
          database: "test'; DROP DATABASE postgres--",
          username: 'testuser'
        ).revoke_privs!
      end.to raise_error(Pgchief::InvalidIdentifierError)
    end

    it 'rejects usernames with SQL injection attempts' do
      expect do
        described_class.new(
          database: 'testdb',
          username: "admin'; GRANT ALL--"
        ).revoke_privs!
      end.to raise_error(Pgchief::InvalidIdentifierError)
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/pgchief/command/database_privileges_revoke_injection_spec.rb -v`
Expected: FAIL

**Step 3: Add validation to DatabasePrivilegesRevoke**

Modify `lib/pgchief/command/database_privileges_revoke.rb`:

```ruby
# frozen_string_literal: true

require 'pg'
require_relative 'base'

module Pgchief
  module Command
    class DatabasePrivilegesRevoke < Base
      REVOKE_QUERIES = [
        'REVOKE CONNECT ON DATABASE %{database} FROM %{username}',
        'REVOKE CREATE ON SCHEMA public FROM %{username}',
        'REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM %{username}',
        'REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM %{username}',
        'ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL PRIVILEGES ON TABLES FROM %{username}',
        'ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL PRIVILEGES ON SEQUENCES FROM %{username}'
      ].freeze

      def initialize(database:, username:)
        @database = Validators.sanitize_identifier(database)
        @username = Validators.sanitize_identifier(username)
        super()
      end

      def revoke_privs!
        db_conn = PG.connect(Pgchief::Config.pgurl + "/#{@database}")

        REVOKE_QUERIES.each do |query_template|
          query = format(query_template, database: @database, username: @username)
          db_conn.exec(query)
        end

        puts "Privileges revoked from #{@username} on #{@database}"
      rescue PG::Error => e
        puts "Error: #{e.message}"
      ensure
        db_conn.close if db_conn && !db_conn.finished?
        conn.close if conn && !conn.finished?
      end

      private

      attr_reader :database, :username
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/pgchief/command/database_privileges_revoke_injection_spec.rb -v`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/pgchief/command/database_privileges_revoke.rb spec/pgchief/command/database_privileges_revoke_injection_spec.rb
git commit -m "fix: prevent SQL injection in privilege revocation

- Add validation for database and username
- Refactor using query constant array
- Add security tests"
```

---

## Task 8: Fix Shell Injection in DatabaseBackup

**Files:**
- Modify: `lib/pgchief/command/database_backup.rb:15,42-44`
- Create: `spec/pgchief/command/database_backup_injection_spec.rb`

**Step 1: Write the failing security test**

Create `spec/pgchief/command/database_backup_injection_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/command/database_backup'

RSpec.describe Pgchief::Command::DatabaseBackup do
  describe 'shell injection protection' do
    it 'rejects database names with shell injection attempts' do
      expect do
        described_class.new(database: 'test; rm -rf /').backup!
      end.to raise_error(Pgchief::InvalidIdentifierError)
    end

    it 'rejects database names with backticks' do
      expect do
        described_class.new(database: 'test`whoami`').backup!
      end.to raise_error(Pgchief::InvalidIdentifierError)
    end

    it 'rejects database names with command substitution' do
      expect do
        described_class.new(database: 'test$(whoami)').backup!
      end.to raise_error(Pgchief::InvalidIdentifierError)
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/pgchief/command/database_backup_injection_spec.rb -v`
Expected: FAIL

**Step 3: Replace backticks with Open3 and add validation**

Modify `lib/pgchief/command/database_backup.rb`:

```ruby
# frozen_string_literal: true

require 'pg'
require 'open3'  # ADD THIS
require_relative 'base'

module Pgchief
  module Command
    class DatabaseBackup < Base
      def initialize(database:)
        @database = Validators.sanitize_identifier(database)  # ADD THIS
        super()
      end

      def backup!
        timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
        filename = "#{@database}_#{timestamp}.dump"
        local_location = File.join(Pgchief::Config.backup_dir, filename)

        # Use Open3 for safe command execution
        pg_dump_url = "#{Pgchief::Config.pgurl}/#{@database}"

        stdout, stderr, status = Open3.capture3(
          'pg_dump',
          '--format=custom',
          '--file', local_location,
          pg_dump_url
        )

        if status.success?
          puts "Backup created: #{local_location}"
          local_location
        else
          raise "pg_dump failed: #{stderr}"
        end
      rescue StandardError => e
        puts "Error: #{e.message}"
        nil
      ensure
        conn.close if conn && !conn.finished?
      end

      private

      attr_reader :database
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/pgchief/command/database_backup_injection_spec.rb -v`
Expected: All tests PASS

**Step 5: Run existing backup tests**

Run: `bundle exec rspec spec/pgchief/command/database_backup_spec.rb -v`
Expected: Tests PASS (may need adjustment if they check specific output)

**Step 6: Commit**

```bash
git add lib/pgchief/command/database_backup.rb spec/pgchief/command/database_backup_injection_spec.rb
git commit -m "fix: prevent shell injection in database backup

- Replace backticks with Open3.capture3
- Add database name validation
- Add security tests for shell injection attempts
- Improve error handling with stderr capture"
```

---

## Task 9: Fix Shell Injection in DatabaseRestore

**Files:**
- Modify: `lib/pgchief/command/database_restore.rb:15,41-43`
- Create: `spec/pgchief/command/database_restore_injection_spec.rb`

**Step 1: Write the failing security test**

Create `spec/pgchief/command/database_restore_injection_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/command/database_restore'

RSpec.describe Pgchief::Command::DatabaseRestore do
  describe 'shell injection protection' do
    it 'rejects database names with shell injection attempts' do
      expect do
        described_class.new(
          database: 'test; rm -rf /',
          location: 'test.dump'
        ).restore!
      end.to raise_error(Pgchief::InvalidIdentifierError)
    end

    it 'rejects file paths with command injection' do
      expect do
        described_class.new(
          database: 'testdb',
          location: 'test.dump; cat /etc/passwd'
        ).restore!
      end.to raise_error(Pgchief::InvalidFilePathError)
    end

    it 'rejects file paths with path traversal' do
      expect do
        described_class.new(
          database: 'testdb',
          location: '../../etc/passwd'
        ).restore!
      end.to raise_error(Pgchief::InvalidFilePathError)
    end
  end
end
```

**Step 2: Add file path validation to Validators**

Add to `lib/pgchief/validators.rb`:

```ruby
# Add to module
class InvalidFilePathError < StandardError; end

# File path validation
def self.valid_file_path?(path)
  return false if path.nil? || path.empty?
  # Prevent path traversal
  return false if path.include?('..')
  # Prevent shell metacharacters
  return false if path.match?(/[;&|`$()]/)
  # Must be an absolute path or relative without ../
  true
end

def self.sanitize_file_path(path)
  unless valid_file_path?(path)
    raise InvalidFilePathError, "Invalid file path: #{path.inspect}"
  end
  # Expand to absolute path for safety
  File.expand_path(path)
end
```

**Step 3: Add tests for file path validation**

Add to `spec/pgchief/validators_spec.rb`:

```ruby
describe '.valid_file_path?' do
  it 'returns true for valid file paths' do
    expect(described_class.valid_file_path?('/tmp/backup.dump')).to be true
    expect(described_class.valid_file_path?('backup.dump')).to be true
  end

  it 'returns false for paths with traversal' do
    expect(described_class.valid_file_path?('../etc/passwd')).to be false
    expect(described_class.valid_file_path?('../../secret')).to be false
  end

  it 'returns false for paths with shell metacharacters' do
    expect(described_class.valid_file_path?('file; rm -rf /')).to be false
    expect(described_class.valid_file_path?('file`whoami`')).to be false
    expect(described_class.valid_file_path?('file$(date)')).to be false
  end
end
```

**Step 4: Run validator tests**

Run: `bundle exec rspec spec/pgchief/validators_spec.rb -v`
Expected: All tests PASS

**Step 5: Replace backticks with Open3 in DatabaseRestore**

Modify `lib/pgchief/command/database_restore.rb`:

```ruby
# frozen_string_literal: true

require 'pg'
require 'open3'  # ADD THIS
require_relative 'base'

module Pgchief
  module Command
    class DatabaseRestore < Base
      def initialize(database:, location:)
        @database = Validators.sanitize_identifier(database)
        @location = Validators.sanitize_file_path(location)
        super()
      end

      def restore!
        unless File.exist?(@location)
          puts "Error: Backup file not found: #{@location}"
          return
        end

        recreate_database!
        restore_from_file!
      rescue StandardError => e
        puts "Error: #{e.message}"
      ensure
        conn.close if conn && !conn.finished?
      end

      private

      attr_reader :database, :location

      def recreate_database!
        # Drop if exists, then create
        conn.exec("DROP DATABASE IF EXISTS #{@database}")
        conn.exec("CREATE DATABASE #{@database}")
      end

      def restore_from_file!
        pg_restore_url = "#{Pgchief::Config.pgurl}/#{@database}"

        stdout, stderr, status = Open3.capture3(
          'pg_restore',
          '--clean',
          '--if-exists',
          '--no-owner',
          "--dbname=#{pg_restore_url}",
          @location
        )

        if status.success?
          puts "Database restored: #{@database}"
        else
          # pg_restore outputs warnings to stderr even on success
          # Only raise if exit status is non-zero
          raise "pg_restore failed: #{stderr}" unless stderr.empty?
          puts "Database restored with warnings: #{stderr}"
        end
      end
    end
  end
end
```

**Step 6: Run test to verify it passes**

Run: `bundle exec rspec spec/pgchief/command/database_restore_injection_spec.rb -v`
Expected: All tests PASS

**Step 7: Commit**

```bash
git add lib/pgchief/validators.rb spec/pgchief/validators_spec.rb lib/pgchief/command/database_restore.rb spec/pgchief/command/database_restore_injection_spec.rb
git commit -m "fix: prevent shell injection in database restore

- Replace backticks with Open3.capture3
- Add file path validation to prevent traversal and injection
- Add database name validation
- Add security tests
- Improve error handling"
```

---

## Task 10: Fix SQL Injection in QuickBackup

**Files:**
- Modify: `lib/pgchief/command/quick_backup.rb:10`

**Step 1: Add validation to QuickBackup**

Modify `lib/pgchief/command/quick_backup.rb`:

```ruby
# frozen_string_literal: true

require_relative 'database_backup'

module Pgchief
  module Command
    class QuickBackup
      def initialize(database:)
        @database = Validators.sanitize_identifier(database)  # ADD THIS
      end

      def backup!
        Pgchief::Command::DatabaseBackup.new(database: database).backup!
      end

      private

      attr_reader :database
    end
  end
end
```

**Step 2: Commit**

```bash
git add lib/pgchief/command/quick_backup.rb
git commit -m "fix: add validation to QuickBackup command

- Add identifier validation to QuickBackup#initialize
- Ensures validation happens even when using quick commands"
```

---

## Task 11: Fix SQL Injection in QuickRestore

**Files:**
- Modify: `lib/pgchief/command/quick_restore.rb:10,14`

**Step 1: Add validation to QuickRestore**

Modify `lib/pgchief/command/quick_restore.rb`:

```ruby
# frozen_string_literal: true

require_relative 'database_restore'

module Pgchief
  module Command
    class QuickRestore
      def initialize(database:, location:)
        @database = Validators.sanitize_identifier(database)
        @location = Validators.sanitize_file_path(location)
      end

      def restore!
        Pgchief::Command::DatabaseRestore.new(
          database: database,
          location: location
        ).restore!
      end

      private

      attr_reader :database, :location
    end
  end
end
```

**Step 2: Commit**

```bash
git add lib/pgchief/command/quick_restore.rb
git commit -m "fix: add validation to QuickRestore command

- Add identifier and file path validation
- Ensures validation in quick restore path"
```

---

## Task 12: Run Full Test Suite

**Step 1: Run all tests**

Run: `bundle exec rspec --format documentation`
Expected: All tests PASS

**Step 2: Check RuboCop compliance**

Run: `bundle exec rubocop`
Expected: No offenses (or only acceptable offenses)

**Step 3: Manual security testing**

Try manual injection attempts:
```bash
# These should all fail with InvalidIdentifierError
bundle exec exe/pgchief database create --database "test; DROP DATABASE postgres"
bundle exec exe/pgchief user create --username "admin' OR '1'='1" --password "test"
bundle exec exe/pgchief backup --database "test\`whoami\`"
```

Expected: All commands reject invalid input with clear error messages

**Step 4: Update CHANGELOG**

Add to `CHANGELOG.md`:

```markdown
## [Unreleased]

### Security
- **CRITICAL**: Fixed SQL injection vulnerabilities in all database and user commands
- **CRITICAL**: Fixed shell injection vulnerabilities in backup/restore commands
- Added comprehensive input validation for database names, usernames, and file paths
- Replaced string interpolation with parameterized queries where possible
- Replaced backtick shell execution with Open3 for safe command execution
- Added security test suite for injection attack scenarios

### Changed
- DatabaseCreate, DatabaseDrop, UserCreate, UserDrop now validate identifiers
- DatabasePrivilegesGrant/Revoke refactored with query constants (fixes RuboCop)
- DatabaseBackup, DatabaseRestore now use Open3 instead of backticks
- All commands now use Validators module for input sanitization
```

**Step 5: Final commit**

```bash
git add CHANGELOG.md
git commit -m "docs: update CHANGELOG for Week 1 security fixes

Document all SQL and shell injection vulnerability fixes"
```

---

## Verification Checklist

- [ ] All SQL queries use parameterized queries OR validated identifiers
- [ ] All shell commands use Open3 instead of backticks
- [ ] All user inputs are validated before use
- [ ] Security tests cover SQL injection attempts
- [ ] Security tests cover shell injection attempts
- [ ] Security tests cover path traversal attempts
- [ ] All existing tests still pass
- [ ] RuboCop passes
- [ ] Manual testing confirms rejection of malicious input
- [ ] CHANGELOG updated

## Notes

- PostgreSQL doesn't support parameterized identifiers (database/table/user names), so we validate them strictly and then use string interpolation
- Passwords use parameterized queries ($1 syntax) for maximum safety
- File paths are expanded to absolute paths to prevent traversal
- Open3.capture3 is safer than backticks as it doesn't invoke a shell
