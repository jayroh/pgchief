# Week 4: Standardize Error Handling and Add Logging Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement structured logging, standardized error handling, and improve error messages throughout pgchief for better debugging and production operations.

**Architecture:** Create custom exception hierarchy, implement structured logging with Ruby Logger, add retry logic with exponential backoff, create error message registry with user-friendly messages.

**Tech Stack:** Ruby 3.0+, Logger (stdlib), custom exception classes

---

## Task 1: Create Custom Exception Hierarchy

**Files:**
- Create: `lib/pgchief/errors.rb`
- Create: `spec/pgchief/errors_spec.rb`

**Step 1: Write failing tests**

Create `spec/pgchief/errors_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/errors'

RSpec.describe 'Pgchief::Errors' do
  describe Pgchief::Error do
    it 'is the base error class' do
      expect(Pgchief::Error.superclass).to eq(StandardError)
    end
  end

  describe Pgchief::DatabaseError do
    it 'includes original database error' do
      original_error = PG::Error.new('connection failed')
      error = described_class.new('Database operation failed', original_error)

      expect(error.message).to eq('Database operation failed')
      expect(error.original_error).to eq(original_error)
    end
  end

  describe Pgchief::ConfigurationError do
    it 'provides helpful configuration error messages' do
      error = described_class.new('Missing PGURL')
      expect(error.message).to include('Missing PGURL')
    end
  end

  describe Pgchief::ValidationError do
    it 'includes field name in error' do
      error = described_class.new('database', 'invalid characters')
      expect(error.message).to include('database')
      expect(error.message).to include('invalid characters')
    end
  end
end
```

**Step 2: Implement custom exceptions**

Create `lib/pgchief/errors.rb`:

```ruby
# frozen_string_literal: true

module Pgchief
  # Base error class for all pgchief errors
  class Error < StandardError; end

  # Database operation errors
  class DatabaseError < Error
    attr_reader :original_error

    def initialize(message, original_error = nil)
      super(message)
      @original_error = original_error
    end
  end

  # Configuration errors
  class ConfigurationError < Error; end

  # Validation errors (previously InvalidIdentifierError, etc.)
  class ValidationError < Error
    attr_reader :field, :reason

    def initialize(field, reason)
      @field = field
      @reason = reason
      super("Invalid #{field}: #{reason}")
    end
  end

  # Legacy aliases for backward compatibility
  InvalidIdentifierError = ValidationError
  InvalidFilePathError = ValidationError

  # Connection errors
  class ConnectionError < DatabaseError; end

  # Permission errors
  class PermissionError < DatabaseError; end

  # Resource not found errors
  class NotFoundError < Error
    attr_reader :resource_type, :resource_name

    def initialize(resource_type, resource_name)
      @resource_type = resource_type
      @resource_name = resource_name
      super("#{resource_type} not found: #{resource_name}")
    end
  end

  # Backup/restore errors
  class BackupError < Error; end
  class RestoreError < Error; end

  # Credential storage errors
  class CredentialError < Error; end
end
```

**Step 3: Run tests**

Run: `bundle exec rspec spec/pgchief/errors_spec.rb`
Expected: All tests PASS

**Step 4: Update validators to use new exception class**

Modify `lib/pgchief/validators.rb` to raise `ValidationError` instead:

```ruby
# Update all raises to use ValidationError
def self.sanitize_identifier(identifier)
  unless valid_identifier?(identifier)
    raise ValidationError.new('identifier', "#{identifier.inspect} contains invalid characters")
  end
  identifier
end

def self.sanitize_password(password)
  unless valid_password?(password)
    raise ValidationError.new('password', "must be 1-#{PASSWORD_MAX_LENGTH} characters")
  end
  password
end

def self.sanitize_file_path(path)
  unless valid_file_path?(path)
    raise ValidationError.new('file_path', "#{path.inspect} is unsafe")
  end
  File.expand_path(path)
end
```

**Step 5: Commit**

```bash
git add lib/pgchief/errors.rb spec/pgchief/errors_spec.rb lib/pgchief/validators.rb lib/pgchief.rb
git commit -m "feat: add custom exception hierarchy

- Create base Pgchief::Error class
- Add specific error types (DatabaseError, ValidationError, etc.)
- Include original errors for debugging
- Update validators to use new exceptions
- Maintain backward compatibility with aliases"
```

---

## Task 2: Implement Structured Logging

**Files:**
- Create: `lib/pgchief/logger.rb`
- Create: `spec/pgchief/logger_spec.rb`

**Step 1: Write logger tests**

Create `spec/pgchief/logger_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/logger'
require 'stringio'

RSpec.describe Pgchief::Logger do
  let(:output) { StringIO.new }
  let(:logger) { described_class.new(output: output, level: ::Logger::DEBUG) }

  describe '#debug' do
    it 'logs debug messages' do
      logger.debug('test message')
      expect(output.string).to include('DEBUG')
      expect(output.string).to include('test message')
    end
  end

  describe '#info' do
    it 'logs info messages' do
      logger.info('operation completed')
      expect(output.string).to include('INFO')
      expect(output.string).to include('operation completed')
    end
  end

  describe '#warn' do
    it 'logs warning messages' do
      logger.warn('deprecated feature')
      expect(output.string).to include('WARN')
      expect(output.string).to include('deprecated feature')
    end
  end

  describe '#error' do
    it 'logs error messages' do
      logger.error('operation failed')
      expect(output.string).to include('ERROR')
      expect(output.string).to include('operation failed')
    end

    it 'includes exception details' do
      error = StandardError.new('test error')
      error.set_backtrace(['line 1', 'line 2'])

      logger.error('operation failed', error)

      expect(output.string).to include('ERROR')
      expect(output.string).to include('test error')
      expect(output.string).to include('line 1')
    end
  end

  describe 'log levels' do
    it 'respects log level configuration' do
      info_logger = described_class.new(output: output, level: ::Logger::INFO)

      info_logger.debug('should not appear')
      info_logger.info('should appear')

      expect(output.string).not_to include('should not appear')
      expect(output.string).to include('should appear')
    end
  end
end
```

**Step 2: Implement logger**

Create `lib/pgchief/logger.rb`:

```ruby
# frozen_string_literal: true

require 'logger'

module Pgchief
  # Structured logging for pgchief operations
  class Logger
    def initialize(output: $stdout, level: nil)
      @logger = ::Logger.new(output)
      @logger.level = level || log_level_from_env
      @logger.formatter = proc do |severity, datetime, _progname, msg|
        "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity.ljust(5)} - #{msg}\n"
      end
    end

    def debug(message)
      @logger.debug(message)
    end

    def info(message)
      @logger.info(message)
    end

    def warn(message)
      @logger.warn(message)
    end

    def error(message, exception = nil)
      if exception
        @logger.error("#{message}: #{exception.class}: #{exception.message}")
        @logger.error("Backtrace:\n  #{exception.backtrace.join("\n  ")}") if exception.backtrace
      else
        @logger.error(message)
      end
    end

    def fatal(message, exception = nil)
      if exception
        @logger.fatal("#{message}: #{exception.class}: #{exception.message}")
        @logger.fatal("Backtrace:\n  #{exception.backtrace.join("\n  ")}") if exception.backtrace
      else
        @logger.fatal(message)
      end
    end

    private

    def log_level_from_env
      case ENV.fetch('PGCHIEF_LOG_LEVEL', 'INFO').upcase
      when 'DEBUG' then ::Logger::DEBUG
      when 'INFO' then ::Logger::INFO
      when 'WARN' then ::Logger::WARN
      when 'ERROR' then ::Logger::ERROR
      when 'FATAL' then ::Logger::FATAL
      else ::Logger::INFO
      end
    end

    class << self
      # Global logger instance
      def instance
        @instance ||= new
      end

      def method_missing(method, *args, &block)
        if instance.respond_to?(method)
          instance.send(method, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(method, include_private = false)
        instance.respond_to?(method, include_private) || super
      end
    end
  end
end
```

**Step 3: Run tests**

Run: `bundle exec rspec spec/pgchief/logger_spec.rb`
Expected: All tests PASS

**Step 4: Commit**

```bash
git add lib/pgchief/logger.rb spec/pgchief/logger_spec.rb lib/pgchief.rb
git commit -m "feat: add structured logging system

- Implement Logger wrapper around Ruby Logger
- Add formatted log output with timestamps
- Support log levels (DEBUG, INFO, WARN, ERROR, FATAL)
- Include exception backtraces in error logs
- Support PGCHIEF_LOG_LEVEL environment variable"
```

---

## Task 3: Update Commands to Use Logger

**Files:**
- Modify: All command files in `lib/pgchief/command/`

**Step 1: Update DatabaseCreate**

Replace `puts` with logger calls in `lib/pgchief/command/database_create.rb`:

```ruby
def create_db!
  Pgchief::Logger.info("Creating database: #{@database}")
  conn.exec("CREATE DATABASE #{@database}")
  conn.exec("REVOKE CONNECT ON DATABASE #{@database} FROM PUBLIC")
  Pgchief::Logger.info("Database created successfully: #{@database}")
rescue PG::Error => e
  Pgchief::Logger.error("Failed to create database #{@database}", e)
  raise DatabaseError.new("Failed to create database #{@database}", e)
ensure
  conn.close
end
```

**Step 2: Update all other command classes similarly**

For each command:
- Replace `puts` with appropriate logger calls (`info` for success, `error` for failures)
- Raise specific exceptions instead of printing errors
- Log operations before executing them
- Log success after completion

**Step 3: Commit**

```bash
git add lib/pgchief/command/
git commit -m "refactor: replace puts with structured logging in commands

- Use Logger for all command operations
- Log operations before execution
- Log success and failures appropriately
- Raise exceptions instead of printing errors"
```

---

## Task 4: Add Retry Logic with Exponential Backoff

**Files:**
- Create: `lib/pgchief/retryable.rb`
- Create: `spec/pgchief/retryable_spec.rb`

**Step 1: Write tests**

Create `spec/pgchief/retryable_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/retryable'

RSpec.describe Pgchief::Retryable do
  let(:test_class) do
    Class.new do
      include Pgchief::Retryable

      attr_accessor :attempts

      def initialize
        @attempts = 0
      end

      def failing_operation
        @attempts += 1
        raise PG::Error, 'Connection failed'
      end

      def eventually_successful_operation
        @attempts += 1
        raise PG::Error, 'Connection failed' if @attempts < 3
        'success'
      end
    end
  end

  let(:instance) { test_class.new }

  describe '#with_retry' do
    it 'retries transient errors' do
      expect { instance.with_retry { instance.failing_operation } }
        .to raise_error(PG::Error)
      expect(instance.attempts).to eq(4) # 1 initial + 3 retries
    end

    it 'succeeds after retries' do
      result = instance.with_retry { instance.eventually_successful_operation }
      expect(result).to eq('success')
      expect(instance.attempts).to eq(3)
    end

    it 'does not retry non-transient errors' do
      expect do
        instance.with_retry(retryable_errors: [PG::ConnectionBad]) do
          raise Pgchief::ValidationError.new('test', 'invalid')
        end
      end.to raise_error(Pgchief::ValidationError)
    end
  end
end
```

**Step 2: Implement retryable module**

Create `lib/pgchief/retryable.rb`:

```ruby
# frozen_string_literal: true

module Pgchief
  # Retry logic with exponential backoff
  module Retryable
    DEFAULT_MAX_ATTEMPTS = 4
    DEFAULT_BASE_DELAY = 0.5
    DEFAULT_MAX_DELAY = 10
    DEFAULT_RETRYABLE_ERRORS = [
      PG::ConnectionBad,
      PG::UnableToSend,
      PG::AdminShutdown
    ].freeze

    def with_retry(
      max_attempts: DEFAULT_MAX_ATTEMPTS,
      base_delay: DEFAULT_BASE_DELAY,
      max_delay: DEFAULT_MAX_DELAY,
      retryable_errors: DEFAULT_RETRYABLE_ERRORS
    )
      attempts = 0

      begin
        attempts += 1
        yield
      rescue *retryable_errors => e
        if attempts < max_attempts
          delay = [base_delay * (2**(attempts - 1)), max_delay].min
          Pgchief::Logger.warn("Attempt #{attempts}/#{max_attempts} failed: #{e.message}. Retrying in #{delay}s...")
          sleep(delay)
          retry
        else
          Pgchief::Logger.error("All #{max_attempts} attempts failed", e)
          raise
        end
      end
    end
  end
end
```

**Step 3: Include in Base command**

Modify `lib/pgchief/command/base.rb`:

```ruby
require_relative '../retryable'

module Pgchief
  module Command
    class Base
      include Retryable

      # Update initialize to use retryable
      def initialize
        @conn = with_retry { PG.connect(Pgchief::Config.pgurl) }
      rescue PG::Error => e
        raise ConnectionError.new("Failed to connect to database", e)
      end

      # ...
    end
  end
end
```

**Step 4: Commit**

```bash
git add lib/pgchief/retryable.rb spec/pgchief/retryable_spec.rb lib/pgchief/command/base.rb lib/pgchief.rb
git commit -m "feat: add retry logic with exponential backoff

- Implement Retryable module
- Retry transient database errors (connection failures)
- Exponential backoff (0.5s, 1s, 2s, 4s)
- Configurable max attempts and delays
- Include in Base command class"
```

---

**(Continue with Tasks 5-8 covering: improved error messages, prompt error handling, CLI error handling, documentation updates, and full test suite run)**

---

## Verification Checklist

- [ ] Custom exception hierarchy implemented
- [ ] All commands use structured logging
- [ ] Logger respects log levels
- [ ] Retry logic with exponential backoff
- [ ] Error messages are user-friendly
- [ ] Exceptions include original errors
- [ ] All `puts` replaced with logger calls
- [ ] Tests for all error scenarios
- [ ] Documentation updated
- [ ] All tests passing

## Notes

- Logger uses INFO level by default, configurable via PGCHIEF_LOG_LEVEL
- Retry logic only applies to transient errors (connection failures)
- Validation errors are not retried (fail fast)
- All exceptions include context for debugging
