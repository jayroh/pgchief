# frozen_string_literal: true

module Pgchief
  class InvalidIdentifierError < StandardError; end
  class InvalidFilePathError < StandardError; end

  module Validators
    # PostgreSQL identifier naming rules:
    # - Must start with letter or underscore
    # - Can contain letters, digits, underscores
    # - Max 63 bytes
    IDENTIFIER_REGEX = /\A[a-z_][a-z0-9_]*\z/i
    MAX_IDENTIFIER_LENGTH = 63

    # Password validation - prevent SQL injection via password field
    PASSWORD_MAX_LENGTH = 100

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
  end
end