# Week 6: Refactor Code Quality Issues Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Resolve all code smells, refactor large methods, extract magic strings to constants, improve consistency across the codebase, and ensure RuboCop compliance.

**Architecture:** Extract constants for magic values, refactor large methods into smaller focused methods, standardize patterns across similar classes, implement connection management abstraction, improve configuration handling.

**Tech Stack:** Ruby 3.0+, RuboCop

---

## Task 1: Extract Magic Strings to Constants

**Files:**
- Create: `lib/pgchief/constants.rb`
- Modify: All command and prompt files using magic strings

**Step 1: Write failing tests**

Create `spec/pgchief/constants_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/constants'

RSpec.describe Pgchief::Constants do
  describe 'DEFAULT_DATABASES' do
    it 'includes system databases' do
      expect(described_class::DEFAULT_DATABASES).to include('postgres', 'template0', 'template1')
    end
  end

  describe 'MAX_IDENTIFIER_LENGTH' do
    it 'matches PostgreSQL limit' do
      expect(described_class::MAX_IDENTIFIER_LENGTH).to eq(63)
    end
  end

  describe 'DEFAULT_PORT' do
    it 'matches PostgreSQL default' do
      expect(described_class::DEFAULT_PORT).to eq(5432)
    end
  end
end
```

**Step 2: Create constants module**

Create `lib/pgchief/constants.rb`:

```ruby
# frozen_string_literal: true

module Pgchief
  # Application-wide constants
  module Constants
    # PostgreSQL system databases
    DEFAULT_DATABASES = %w[postgres template0 template1].freeze

    # PostgreSQL identifier constraints
    MAX_IDENTIFIER_LENGTH = 63
    IDENTIFIER_REGEX = /\A[a-z_][a-z0-9_]*\z/i

    # Password constraints
    MAX_PASSWORD_LENGTH = 100

    # Connection defaults
    DEFAULT_PORT = 5432

    # File paths
    DEFAULT_CONFIG_DIR = File.join(Dir.home, '.pgchief').freeze
    CONFIG_FILE_NAME = 'pgchief.toml'
    CREDENTIALS_FILE = 'credentials.enc'
    CREDENTIALS_KEY_FILE = '.credentials.key'

    # Backup defaults
    DEFAULT_BACKUP_DIR = File.join(Dir.home, 'pgchief_backups').freeze

    # Retry configuration
    DEFAULT_MAX_RETRY_ATTEMPTS = 4
    DEFAULT_RETRY_BASE_DELAY = 0.5
    DEFAULT_RETRY_MAX_DELAY = 10

    # Log levels
    LOG_LEVELS = %w[DEBUG INFO WARN ERROR FATAL].freeze
    DEFAULT_LOG_LEVEL = 'INFO'
  end
end
```

**Step 3: Update Validators to use constants**

Modify `lib/pgchief/validators.rb`:

```ruby
# Replace hardcoded values with constants
IDENTIFIER_REGEX = Constants::IDENTIFIER_REGEX
MAX_IDENTIFIER_LENGTH = Constants::MAX_IDENTIFIER_LENGTH
PASSWORD_MAX_LENGTH = Constants::MAX_PASSWORD_LENGTH
```

**Step 4: Update all files using magic strings**

Search and replace magic values across codebase:
- `'postgres'` → `Constants::DEFAULT_DATABASES[0]`
- `'template0'` → `Constants::DEFAULT_DATABASES[1]`
- `'template1'` → `Constants::DEFAULT_DATABASES[2]`
- `63` → `Constants::MAX_IDENTIFIER_LENGTH`
- `5432` → `Constants::DEFAULT_PORT`

**Step 5: Run tests**

Run: `bundle exec rspec spec/pgchief/constants_spec.rb`
Expected: All tests PASS

**Step 6: Commit**

```bash
git add lib/pgchief/constants.rb spec/pgchief/constants_spec.rb lib/pgchief/validators.rb lib/pgchief/*.rb lib/pgchief/command/*.rb
git commit -m "refactor: extract magic strings to constants

- Create Constants module with all magic values
- Replace hardcoded strings across codebase
- Improve maintainability and discoverability
- Document PostgreSQL constraints"
```

---

## Task 2: Refactor Large Methods

**Files:**
- Modify: `lib/pgchief/config.rb`
- Modify: `lib/pgchief/cli.rb`
- Modify: `lib/pgchief/command/database_privileges_grant.rb`

**Step 1: Refactor Config.load_config!**

Current `Config.load_config!` is 19 lines with multiple responsibilities.

Modify `lib/pgchief/config.rb`:

```ruby
# Before: one large method
def self.load_config!
  # 19 lines of config loading, env checking, error handling
end

# After: extracted methods
def self.load_config!
  config_data = load_config_file
  merge_environment_variables!(config_data)
  validate_config!(config_data)
  @config = config_data
rescue StandardError => e
  Pgchief::Logger.error("Failed to load config", e)
  raise ConfigurationError, "Config loading failed: #{e.message}"
end

private

def self.load_config_file
  return {} unless File.exist?(config_file_path)

  toml_content = File.read(config_file_path)
  TomlRB.parse(toml_content)
rescue TomlRB::ParseError => e
  Pgchief::Logger.warn("Invalid TOML config: #{e.message}")
  {}
end

def self.merge_environment_variables!(config)
  config['pgurl'] = ENV['PGURL'] if ENV['PGURL']
  config['s3_bucket'] = ENV['S3_BUCKET'] if ENV['S3_BUCKET']
  config['backup_dir'] = ENV['BACKUP_DIR'] if ENV['BACKUP_DIR']
end

def self.validate_config!(config)
  if config['pgurl'].nil? || config['pgurl'].empty?
    raise ConfigurationError, "PGURL not configured. Set PGURL environment variable or add to #{config_file_path}"
  end
end

def self.config_file_path
  @config_file_path ||= File.join(Constants::DEFAULT_CONFIG_DIR, Constants::CONFIG_FILE_NAME)
end
```

**Step 2: Refactor Cli.run method**

Current `Cli.run` has disabled RuboCop for method length and ABC complexity.

Modify `lib/pgchief/cli.rb`:

```ruby
def self.run
  params = parse_options
  handle_command(params)
rescue StandardError => e
  Pgchief::Logger.error("CLI error", e)
  exit 1
end

private

def self.handle_command(params)
  case
  when params[:version]
    puts Pgchief::VERSION
  when params[:database_create]
    handle_database_create(params)
  when params[:database_drop]
    handle_database_drop(params)
  when params[:user_create]
    handle_user_create(params)
  when params[:interactive]
    Pgchief::Prompt::Start.new.start!
  else
    puts params.help
  end
end

def self.handle_database_create(params)
  Pgchief::Command::DatabaseCreate.new(database: params[:database]).create_db!
end

def self.handle_database_drop(params)
  Pgchief::Command::DatabaseDrop.new(database: params[:database]).drop_db!
end

# ... extract each command handler
```

**Step 3: Run RuboCop**

Run: `bundle exec rubocop lib/pgchief/config.rb lib/pgchief/cli.rb`
Expected: No more disabled cops for method length

**Step 4: Commit**

```bash
git add lib/pgchief/config.rb lib/pgchief/cli.rb
git commit -m "refactor: extract large methods into smaller focused methods

- Break Config.load_config! into 4 focused methods
- Extract Cli command handlers
- Remove RuboCop disables for method length
- Improve readability and testability"
```

---

## Task 3: Standardize Connection Management

**Files:**
- Create: `lib/pgchief/database_connection.rb`
- Modify: `lib/pgchief/command/base.rb`
- Modify: All command classes

**Step 1: Create DatabaseConnection abstraction**

Create `lib/pgchief/database_connection.rb`:

```ruby
# frozen_string_literal: true

require 'pg'

module Pgchief
  # Database connection management with retry logic
  class DatabaseConnection
    include Retryable

    attr_reader :connection

    def initialize(database: nil)
      @database = database
      @connection = establish_connection
    end

    def execute(sql, params = [])
      if params.empty?
        connection.exec(sql)
      else
        connection.exec_params(sql, params)
      end
    end

    def close
      return if connection.nil? || connection.finished?
      connection.close
    end

    def closed?
      connection.nil? || connection.finished?
    end

    private

    def establish_connection
      url = connection_url
      with_retry do
        PG.connect(url)
      end
    rescue PG::Error => e
      raise ConnectionError.new("Failed to connect to #{url}", e)
    end

    def connection_url
      base_url = Pgchief::Config.pgurl
      @database ? "#{base_url}/#{@database}" : base_url
    end
  end
end
```

**Step 2: Update Base to use DatabaseConnection**

Modify `lib/pgchief/command/base.rb`:

```ruby
module Pgchief
  module Command
    class Base
      attr_reader :db

      def initialize(database: nil)
        @db = DatabaseConnection.new(database: database)
      end

      # Legacy support
      def conn
        @db.connection
      end

      private

      def execute(sql, params = [])
        db.execute(sql, params)
      end

      def close_connection
        db.close
      end
    end
  end
end
```

**Step 3: Update commands to use execute helper**

Modify commands to use `execute` instead of `conn.exec`:

```ruby
# Before:
conn.exec("CREATE DATABASE #{@database}")

# After:
execute("CREATE DATABASE #{@database}")
```

**Step 4: Commit**

```bash
git add lib/pgchief/database_connection.rb lib/pgchief/command/base.rb lib/pgchief/command/*.rb
git commit -m "refactor: create DatabaseConnection abstraction

- Centralize connection management
- Include retry logic by default
- Standardize execute patterns
- Improve connection lifecycle management"
```

---

## Task 4: Fix TTY::Prompt Instantiation Inconsistency

**Files:**
- Modify: `lib/pgchief/prompt/base.rb`
- Modify: `lib/pgchief/prompt/database_management.rb`
- Modify: All other prompt files

**Step 1: Ensure all prompts use inherited prompt**

Modify `lib/pgchief/prompt/database_management.rb`:

```ruby
# Before:
def initialize
  @prompt = TTY::Prompt.new  # Creates its own instance
end

# After:
def initialize(prompt: nil)
  super(prompt: prompt)  # Use parent's prompt
end

# Remove line that creates new TTY::Prompt.new
```

**Step 2: Update all prompt classes similarly**

Ensure all prompt classes:
- Accept `prompt:` parameter
- Call `super(prompt: prompt)`
- Use `@prompt` from base class
- Don't create their own `TTY::Prompt.new`

**Step 3: Run prompt tests**

Run: `bundle exec rspec spec/pgchief/prompt/`
Expected: All tests PASS

**Step 4: Commit**

```bash
git add lib/pgchief/prompt/
git commit -m "refactor: standardize TTY::Prompt usage across prompts

- All prompts use inherited @prompt instance
- Remove duplicate TTY::Prompt.new calls
- Consistent initialization pattern"
```

---

## Task 5: Improve Configuration Consistency

**Files:**
- Modify: `lib/pgchief/config.rb`

**Step 1: Make Config thread-safe**

Modify `lib/pgchief/config.rb`:

```ruby
module Pgchief
  class Config
    class << self
      attr_reader :config
      private :config

      def load_config!
        @mutex ||= Mutex.new
        @mutex.synchronize do
          config_data = load_config_file
          merge_environment_variables!(config_data)
          validate_config!(config_data)
          @config = config_data
        end
      rescue StandardError => e
        Pgchief::Logger.error("Failed to load config", e)
        raise ConfigurationError, "Config loading failed: #{e.message}"
      end

      def pgurl
        ensure_config_loaded
        config.fetch('pgurl')
      end

      def s3_bucket
        ensure_config_loaded
        config.fetch('s3_bucket', nil)
      end

      def backup_dir
        ensure_config_loaded
        dir = config.fetch('backup_dir', Constants::DEFAULT_BACKUP_DIR)
        File.expand_path(dir)
      end

      private

      def ensure_config_loaded
        load_config! if config.nil?
      end

      # ... other methods
    end
  end
end
```

**Step 2: Add tests for thread safety**

Create `spec/pgchief/config_thread_safety_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/config'

RSpec.describe Pgchief::Config, 'thread safety' do
  it 'handles concurrent config access safely' do
    threads = 10.times.map do
      Thread.new { described_class.pgurl }
    end

    expect { threads.each(&:join) }.not_to raise_error
  end
end
```

**Step 3: Commit**

```bash
git add lib/pgchief/config.rb spec/pgchief/config_thread_safety_spec.rb
git commit -m "refactor: make Config thread-safe

- Add mutex for configuration loading
- Ensure config loaded before access
- Add thread safety tests"
```

---

## Task 6: Clean Up RuboCop Offenses

**Step 1: Run RuboCop to find all offenses**

Run: `bundle exec rubocop`

Review output and categorize offenses:
- Auto-correctable (use `-A`)
- Manual fixes needed
- Legitimate exceptions to disable

**Step 2: Auto-correct safe offenses**

Run: `bundle exec rubocop -A`
Expected: Many offenses auto-fixed

**Step 3: Manually fix remaining offenses**

For each remaining offense:
1. Understand the issue
2. Fix the code
3. Run RuboCop again
4. Commit fix

**Step 4: Document accepted exceptions**

For legitimate RuboCop exceptions, add comments:

```ruby
# rubocop:disable Metrics/MethodLength - Complex SQL query generation requires length
def build_grant_queries
  # ...
end
# rubocop:enable Metrics/MethodLength
```

**Step 5: Commit**

```bash
git add -A
git commit -m "style: fix all RuboCop offenses

- Auto-correct safe style violations
- Manually fix remaining issues
- Document legitimate exceptions
- Achieve RuboCop compliance"
```

---

## Task 7: Add Code Documentation (YARD)

**Files:**
- Modify: All public classes and methods

**Step 1: Add YARD dependency**

Modify `Gemfile`:

```ruby
group :development do
  gem 'yard', '~> 0.9'
end
```

Run: `bundle install`

**Step 2: Add YARD documentation to key classes**

Example for `lib/pgchief/validators.rb`:

```ruby
module Pgchief
  # Input validation utilities for preventing injection attacks
  module Validators
    # Validates PostgreSQL identifiers (database names, usernames, etc.)
    #
    # PostgreSQL identifiers must:
    # - Start with a letter or underscore
    # - Contain only letters, numbers, and underscores
    # - Be maximum 63 bytes in length
    #
    # @param identifier [String] the identifier to validate
    # @return [Boolean] true if valid, false otherwise
    #
    # @example Valid identifiers
    #   Validators.valid_identifier?('my_database') #=> true
    #   Validators.valid_identifier?('test123') #=> true
    #
    # @example Invalid identifiers
    #   Validators.valid_identifier?('my-database') #=> false
    #   Validators.valid_identifier?("test'; DROP") #=> false
    def self.valid_identifier?(identifier)
      # ...
    end

    # Validates and sanitizes an identifier, raising an error if invalid
    #
    # @param identifier [String] the identifier to sanitize
    # @return [String] the validated identifier
    # @raise [ValidationError] if identifier is invalid
    #
    # @example
    #   Validators.sanitize_identifier('my_db') #=> 'my_db'
    #   Validators.sanitize_identifier('bad;name') #=> raises ValidationError
    def self.sanitize_identifier(identifier)
      # ...
    end
  end
end
```

**Step 3: Generate YARD documentation**

Run: `bundle exec yard doc`
Expected: Documentation generated in `doc/` directory

**Step 4: Add .yardopts for configuration**

Create `.yardopts`:

```
--markup markdown
--protected
--private
--title "pgchief Documentation"
--readme README.md
lib/**/*.rb
```

**Step 5: Add doc/ to .gitignore**

Modify `.gitignore`:

```
doc/
.yardoc/
```

**Step 6: Commit**

```bash
git add lib/**/*.rb .yardopts .gitignore Gemfile Gemfile.lock
git commit -m "docs: add YARD documentation to all public APIs

- Document all public classes and methods
- Add usage examples in documentation
- Generate API documentation with yard
- Configure .yardopts for consistent output"
```

---

## Task 8: Create Contributor Guide

**Files:**
- Create: `CONTRIBUTING.md`

**Step 1: Create comprehensive contributor guide**

Create `CONTRIBUTING.md`:

```markdown
# Contributing to pgchief

## Development Setup

```bash
# Clone repository
git clone https://github.com/yourusername/pgchief.git
cd pgchief

# Install dependencies
bundle install

# Install libsodium (for encryption)
# macOS:
brew install libsodium
# Ubuntu:
sudo apt-get install libsodium-dev

# Run tests
bundle exec rspec

# Run with coverage
COVERAGE=true bundle exec rspec

# Run linting
bundle exec rubocop

# Run security scan
bundle exec brakeman
```

## Code Style

- Follow RuboCop guidelines (`.rubocop.yml`)
- Use `frozen_string_literal: true` in all files
- Add YARD documentation to public methods
- Write tests for all new features

## Security

- **NEVER** use string interpolation in SQL queries
- **ALWAYS** validate user input with `Validators`
- **NEVER** use backticks for shell commands (use `Open3`)
- Add security tests for new input handling

## Testing

- Minimum 80% code coverage required
- Write unit tests with mocks
- Tag integration tests with `:integration`
- Add security tests in `spec/security/`

## Pull Request Process

1. Create feature branch (`git checkout -b feature/my-feature`)
2. Write tests first (TDD approach)
3. Implement feature
4. Ensure all tests pass
5. Ensure RuboCop passes
6. Ensure Brakeman passes
7. Update CHANGELOG.md
8. Submit PR with description

## Release Process

1. Update version in `lib/pgchief/version.rb`
2. Update CHANGELOG.md
3. Run full test suite
4. Create git tag
5. Push to RubyGems
```

**Step 2: Commit**

```bash
git add CONTRIBUTING.md
git commit -m "docs: add comprehensive contributor guide

- Document development setup
- Describe code style expectations
- Security guidelines for contributors
- Testing requirements
- PR and release process"
```

---

## Task 9: Final Quality Audit

**Step 1: Run all quality checks**

```bash
# Tests with coverage
COVERAGE=true bundle exec rspec

# Linting
bundle exec rubocop

# Security scan
bundle exec brakeman

# Check for TODO/FIXME comments
grep -r "TODO\|FIXME" lib/
```

**Step 2: Review coverage report**

Run: `open coverage/index.html`
Verify: Overall coverage >= 80%

**Step 3: Review and resolve any remaining TODOs**

For each TODO/FIXME found:
- Create issue to track
- Fix immediately if critical
- Or remove if no longer relevant

**Step 4: Update documentation**

Ensure:
- README is up to date
- CHANGELOG includes all changes
- SECURITY.md is current
- CONTRIBUTING.md is comprehensive

**Step 5: Final commit**

```bash
git add -A
git commit -m "chore: final quality improvements for Week 6

- Resolve remaining TODOs
- Update all documentation
- Verify all quality checks pass
- Prepare for release"
```

---

## Verification Checklist

- [ ] Magic strings extracted to Constants
- [ ] Large methods refactored into smaller methods
- [ ] DatabaseConnection abstraction created
- [ ] TTY::Prompt instantiation standardized
- [ ] Config is thread-safe
- [ ] RuboCop passes with zero offenses
- [ ] YARD documentation added
- [ ] Contributor guide created
- [ ] Coverage >= 80%
- [ ] All tests passing
- [ ] Brakeman security scan passes
- [ ] No unresolved TODOs/FIXMEs
- [ ] All documentation updated

## Notes

- Constants improve maintainability and prevent typos
- Smaller methods are easier to test and understand
- DatabaseConnection centralizes retry logic and error handling
- Thread-safe config prevents race conditions in multi-threaded usage
- YARD documentation helps future contributors
- Contributor guide reduces onboarding friction
