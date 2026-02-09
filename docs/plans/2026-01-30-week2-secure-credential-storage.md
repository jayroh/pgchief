# Week 2: Implement Secure Credential Storage Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace plain-text credential storage with encrypted credential storage using system keychain where available, with secure file-based fallback.

**Architecture:** Implement a CredentialStore abstraction with multiple backends: system keychain (macOS Keychain, Linux Secret Service, Windows Credential Manager) and encrypted file storage using AES-256-GCM. Use the keyring gem for cross-platform keychain support and the rbnacl gem for encryption.

**Tech Stack:** Ruby 3.0+, keyring gem, rbnacl/libsodium gem, securerandom (stdlib)

---

## Task 1: Add Encryption Dependencies

**Files:**
- Modify: `pgchief.gemspec`
- Modify: `Gemfile`

**Step 1: Add gems to gemspec**

Modify `pgchief.gemspec`:

```ruby
# In the dependencies section, add:
spec.add_dependency 'keyring', '~> 0.3'  # Cross-platform keychain
spec.add_dependency 'rbnacl', '~> 7.1'   # Encryption (uses libsodium)
```

**Step 2: Install dependencies**

Run: `bundle install`
Expected: Gems install successfully (may require libsodium system package)

**Step 3: Add note to README about libsodium**

Modify `README.md` - add to installation section:

```markdown
### System Requirements

pgchief requires libsodium for secure credential storage:

**macOS:**
```bash
brew install libsodium
```

**Ubuntu/Debian:**
```bash
sudo apt-get install libsodium-dev
```

**Fedora/RHEL:**
```bash
sudo dnf install libsodium-devel
```
```

**Step 4: Commit**

```bash
git add pgchief.gemspec Gemfile Gemfile.lock README.md
git commit -m "deps: add encryption dependencies for secure credentials

- Add keyring gem for cross-platform keychain access
- Add rbnacl gem for AES-256-GCM encryption
- Document libsodium system requirement"
```

---

## Task 2: Create Encryption Module

**Files:**
- Create: `lib/pgchief/encryption.rb`
- Create: `spec/pgchief/encryption_spec.rb`

**Step 1: Write failing tests**

Create `spec/pgchief/encryption_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/encryption'

RSpec.describe Pgchief::Encryption do
  describe '.encrypt and .decrypt' do
    it 'encrypts and decrypts data successfully' do
      plaintext = 'postgresql://user:password@localhost/dbname'
      key = described_class.generate_key

      encrypted = described_class.encrypt(plaintext, key)
      expect(encrypted).not_to eq(plaintext)
      expect(encrypted).to be_a(String)

      decrypted = described_class.decrypt(encrypted, key)
      expect(decrypted).to eq(plaintext)
    end

    it 'produces different ciphertext each time (nonce changes)' do
      plaintext = 'secret data'
      key = described_class.generate_key

      encrypted1 = described_class.encrypt(plaintext, key)
      encrypted2 = described_class.encrypt(plaintext, key)

      expect(encrypted1).not_to eq(encrypted2)
      expect(described_class.decrypt(encrypted1, key)).to eq(plaintext)
      expect(described_class.decrypt(encrypted2, key)).to eq(plaintext)
    end

    it 'raises error when decrypting with wrong key' do
      plaintext = 'secret'
      key1 = described_class.generate_key
      key2 = described_class.generate_key

      encrypted = described_class.encrypt(plaintext, key1)

      expect { described_class.decrypt(encrypted, key2) }
        .to raise_error(RbNaCl::CryptoError)
    end

    it 'raises error when decrypting tampered data' do
      plaintext = 'secret'
      key = described_class.generate_key

      encrypted = described_class.encrypt(plaintext, key)
      tampered = encrypted.reverse

      expect { described_class.decrypt(tampered, key) }
        .to raise_error
    end
  end

  describe '.generate_key' do
    it 'generates a random key of correct length' do
      key = described_class.generate_key
      expect(key.bytesize).to eq(32) # 256 bits
    end

    it 'generates different keys each time' do
      key1 = described_class.generate_key
      key2 = described_class.generate_key
      expect(key1).not_to eq(key2)
    end
  end

  describe '.key_to_hex and .hex_to_key' do
    it 'converts key to hex and back' do
      key = described_class.generate_key
      hex = described_class.key_to_hex(key)

      expect(hex).to match(/\A[0-9a-f]{64}\z/)

      restored_key = described_class.hex_to_key(hex)
      expect(restored_key).to eq(key)
    end
  end
end
```

**Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/pgchief/encryption_spec.rb -v`
Expected: FAIL - file doesn't exist

**Step 3: Implement encryption module**

Create `lib/pgchief/encryption.rb`:

```ruby
# frozen_string_literal: true

require 'rbnacl'
require 'base64'

module Pgchief
  # Encryption utilities using libsodium (via rbnacl)
  # Uses XSalsa20-Poly1305 authenticated encryption
  module Encryption
    KEY_BYTES = RbNaCl::SecretBox.key_bytes # 32 bytes = 256 bits

    # Generate a random encryption key
    def self.generate_key
      RbNaCl::Random.random_bytes(KEY_BYTES)
    end

    # Encrypt plaintext with key, returns Base64-encoded ciphertext
    def self.encrypt(plaintext, key)
      box = RbNaCl::SecretBox.new(key)
      nonce = RbNaCl::Random.random_bytes(box.nonce_bytes)

      ciphertext = box.encrypt(nonce, plaintext)

      # Prepend nonce to ciphertext, encode as Base64
      Base64.strict_encode64(nonce + ciphertext)
    end

    # Decrypt Base64-encoded ciphertext with key
    def self.decrypt(encrypted_base64, key)
      box = RbNaCl::SecretBox.new(key)

      # Decode from Base64
      data = Base64.strict_decode64(encrypted_base64)

      # Extract nonce and ciphertext
      nonce = data[0...box.nonce_bytes]
      ciphertext = data[box.nonce_bytes..]

      box.decrypt(nonce, ciphertext)
    end

    # Convert binary key to hex string for storage
    def self.key_to_hex(key)
      key.unpack1('H*')
    end

    # Convert hex string to binary key
    def self.hex_to_key(hex)
      [hex].pack('H*')
    end
  end
end
```

**Step 4: Run tests to verify they pass**

Run: `bundle exec rspec spec/pgchief/encryption_spec.rb -v`
Expected: All tests PASS

**Step 5: Require encryption module**

Modify `lib/pgchief.rb`:

```ruby
# Add with other requires
require_relative 'pgchief/encryption'
```

**Step 6: Commit**

```bash
git add lib/pgchief/encryption.rb spec/pgchief/encryption_spec.rb lib/pgchief.rb
git commit -m "feat: add encryption module using libsodium

- Implement encrypt/decrypt using XSalsa20-Poly1305
- Add authenticated encryption (prevents tampering)
- Add key generation and hex encoding utilities
- Add comprehensive tests including tampering detection"
```

---

## Task 3: Create CredentialStore Abstraction

**Files:**
- Create: `lib/pgchief/credential_store.rb`
- Create: `spec/pgchief/credential_store_spec.rb`

**Step 1: Write failing tests**

Create `spec/pgchief/credential_store_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/credential_store'

RSpec.describe Pgchief::CredentialStore do
  let(:store) { described_class.new }
  let(:test_key) { 'test_connection' }
  let(:test_value) { 'postgresql://user:password@localhost/testdb' }

  describe '#store' do
    it 'stores a credential' do
      expect { store.store(test_key, test_value) }.not_to raise_error
    end

    it 'validates key format' do
      expect { store.store('bad key!', test_value) }
        .to raise_error(Pgchief::InvalidIdentifierError)
    end
  end

  describe '#retrieve' do
    it 'retrieves a stored credential' do
      store.store(test_key, test_value)
      expect(store.retrieve(test_key)).to eq(test_value)
    end

    it 'returns nil for non-existent credentials' do
      expect(store.retrieve('nonexistent')).to be_nil
    end

    it 'validates key format' do
      expect { store.retrieve('bad key!') }
        .to raise_error(Pgchief::InvalidIdentifierError)
    end
  end

  describe '#delete' do
    it 'deletes a stored credential' do
      store.store(test_key, test_value)
      store.delete(test_key)
      expect(store.retrieve(test_key)).to be_nil
    end

    it 'handles deletion of non-existent credentials' do
      expect { store.delete('nonexistent') }.not_to raise_error
    end
  end

  describe '#list' do
    it 'lists all stored credential keys' do
      store.store('connection1', 'value1')
      store.store('connection2', 'value2')

      list = store.list
      expect(list).to include('connection1', 'connection2')
    end

    it 'returns empty array when no credentials stored' do
      expect(store.list).to eq([])
    end
  end
end
```

**Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/pgchief/credential_store_spec.rb -v`
Expected: FAIL

**Step 3: Implement CredentialStore with backend selection**

Create `lib/pgchief/credential_store.rb`:

```ruby
# frozen_string_literal: true

require 'keyring'
require_relative 'credential_store/keychain_backend'
require_relative 'credential_store/encrypted_file_backend'

module Pgchief
  # Credential storage abstraction
  # Tries to use system keychain, falls back to encrypted file
  class CredentialStore
    SERVICE_NAME = 'pgchief'

    def initialize(backend: nil)
      @backend = backend || select_backend
    end

    def store(key, value)
      validate_key!(key)
      backend.store(key, value)
    end

    def retrieve(key)
      validate_key!(key)
      backend.retrieve(key)
    end

    def delete(key)
      validate_key!(key)
      backend.delete(key)
    end

    def list
      backend.list
    end

    private

    attr_reader :backend

    def select_backend
      # Try keychain first, fall back to encrypted file
      if keychain_available?
        KeychainBackend.new
      else
        EncryptedFileBackend.new
      end
    end

    def keychain_available?
      # Test if we can access the keychain
      Keyring.new(SERVICE_NAME, 'test').get_password
      true
    rescue Keyring::Errors::BackendNotFound, Keyring::Errors::InitializationError
      false
    end

    def validate_key!(key)
      Validators.sanitize_identifier(key)
    end
  end
end
```

**Step 4: This will fail because we haven't created the backends yet**

Expected: Will fail to load due to missing backend files

---

## Task 4: Implement Keychain Backend

**Files:**
- Create: `lib/pgchief/credential_store/keychain_backend.rb`

**Step 1: Implement keychain backend**

Create `lib/pgchief/credential_store/keychain_backend.rb`:

```ruby
# frozen_string_literal: true

require 'keyring'

module Pgchief
  class CredentialStore
    # Backend that uses system keychain (macOS Keychain, GNOME Keyring, etc.)
    class KeychainBackend
      SERVICE_NAME = 'pgchief'

      def store(key, value)
        keyring(key).set_password(value)
      end

      def retrieve(key)
        keyring(key).get_password
      rescue Keyring::Errors::EmptyUsername, Keyring::Errors::PasswordNotFound
        nil
      end

      def delete(key)
        keyring(key).delete_password
      rescue Keyring::Errors::PasswordNotFound
        # Already deleted, no-op
      end

      def list
        # Keyring gem doesn't support listing, so we can't implement this
        # without storing a manifest elsewhere. For now, return empty array.
        # Users need to remember their credential names.
        []
      end

      private

      def keyring(username)
        Keyring.new(SERVICE_NAME, username)
      end
    end
  end
end
```

**Step 2: Commit**

```bash
git add lib/pgchief/credential_store/keychain_backend.rb
git commit -m "feat: add keychain backend for credential storage

- Use system keychain when available (macOS, Linux, Windows)
- Implement store/retrieve/delete operations
- Graceful handling of missing credentials"
```

---

## Task 5: Implement Encrypted File Backend

**Files:**
- Create: `lib/pgchief/credential_store/encrypted_file_backend.rb`
- Create: `spec/pgchief/credential_store/encrypted_file_backend_spec.rb`

**Step 1: Write failing tests**

Create `spec/pgchief/credential_store/encrypted_file_backend_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/credential_store/encrypted_file_backend'
require 'fileutils'
require 'tmpdir'

RSpec.describe Pgchief::CredentialStore::EncryptedFileBackend do
  let(:temp_dir) { Dir.mktmpdir }
  let(:backend) { described_class.new(storage_dir: temp_dir) }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '#store and #retrieve' do
    it 'stores and retrieves encrypted credentials' do
      backend.store('test_key', 'secret_value')
      expect(backend.retrieve('test_key')).to eq('secret_value')
    end

    it 'encrypts credentials in the file' do
      backend.store('test_key', 'secret_value')

      # Read the raw file
      credentials_file = File.join(temp_dir, 'credentials.enc')
      raw_content = File.read(credentials_file)

      # Should not contain plaintext
      expect(raw_content).not_to include('secret_value')
      expect(raw_content).not_to include('test_key')
    end

    it 'returns nil for non-existent credentials' do
      expect(backend.retrieve('nonexistent')).to be_nil
    end
  end

  describe '#delete' do
    it 'deletes a stored credential' do
      backend.store('test_key', 'value')
      backend.delete('test_key')
      expect(backend.retrieve('test_key')).to be_nil
    end
  end

  describe '#list' do
    it 'lists all stored credential keys' do
      backend.store('key1', 'value1')
      backend.store('key2', 'value2')

      expect(backend.list).to contain_exactly('key1', 'key2')
    end

    it 'returns empty array when no credentials' do
      expect(backend.list).to eq([])
    end
  end

  describe 'file permissions' do
    it 'creates credentials file with secure permissions (0600)' do
      backend.store('test', 'value')

      credentials_file = File.join(temp_dir, 'credentials.enc')
      stat = File.stat(credentials_file)
      mode = stat.mode & 0o777

      expect(mode).to eq(0o600)
    end

    it 'creates key file with secure permissions (0600)' do
      backend.store('test', 'value')

      key_file = File.join(temp_dir, '.credentials.key')
      stat = File.stat(key_file)
      mode = stat.mode & 0o777

      expect(mode).to eq(0o600)
    end
  end

  describe 'encryption key management' do
    it 'persists encryption key across instances' do
      backend1 = described_class.new(storage_dir: temp_dir)
      backend1.store('test', 'value')

      backend2 = described_class.new(storage_dir: temp_dir)
      expect(backend2.retrieve('test')).to eq('value')
    end

    it 'generates new key if key file is missing' do
      backend.store('test', 'value')

      # Delete key file
      key_file = File.join(temp_dir, '.credentials.key')
      File.delete(key_file)

      # New backend can't decrypt old credentials
      backend2 = described_class.new(storage_dir: temp_dir)
      expect { backend2.retrieve('test') }.to raise_error(RbNaCl::CryptoError)
    end
  end
end
```

**Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/pgchief/credential_store/encrypted_file_backend_spec.rb -v`
Expected: FAIL

**Step 3: Implement encrypted file backend**

Create `lib/pgchief/credential_store/encrypted_file_backend.rb`:

```ruby
# frozen_string_literal: true

require 'json'
require 'fileutils'
require_relative '../encryption'

module Pgchief
  class CredentialStore
    # Backend that stores credentials in an encrypted JSON file
    class EncryptedFileBackend
      DEFAULT_STORAGE_DIR = File.join(Dir.home, '.pgchief')
      CREDENTIALS_FILE = 'credentials.enc'
      KEY_FILE = '.credentials.key'

      def initialize(storage_dir: DEFAULT_STORAGE_DIR)
        @storage_dir = storage_dir
        @credentials_path = File.join(storage_dir, CREDENTIALS_FILE)
        @key_path = File.join(storage_dir, KEY_FILE)

        ensure_storage_dir!
        ensure_key!
      end

      def store(key, value)
        credentials = load_credentials
        credentials[key] = value
        save_credentials(credentials)
      end

      def retrieve(key)
        credentials = load_credentials
        credentials[key]
      end

      def delete(key)
        credentials = load_credentials
        credentials.delete(key)
        save_credentials(credentials)
      end

      def list
        load_credentials.keys
      end

      private

      attr_reader :storage_dir, :credentials_path, :key_path

      def ensure_storage_dir!
        FileUtils.mkdir_p(storage_dir) unless Dir.exist?(storage_dir)
      end

      def ensure_key!
        return if File.exist?(key_path)

        # Generate new encryption key
        key = Encryption.generate_key
        key_hex = Encryption.key_to_hex(key)

        File.write(key_path, key_hex)
        File.chmod(0o600, key_path)
      end

      def load_key
        key_hex = File.read(key_path)
        Encryption.hex_to_key(key_hex.strip)
      end

      def load_credentials
        return {} unless File.exist?(credentials_path)

        encrypted_data = File.read(credentials_path)
        return {} if encrypted_data.empty?

        json_data = Encryption.decrypt(encrypted_data, load_key)
        JSON.parse(json_data)
      rescue JSON::ParserError, RbNaCl::CryptoError
        # Corrupted file, start fresh
        {}
      end

      def save_credentials(credentials)
        json_data = JSON.generate(credentials)
        encrypted_data = Encryption.encrypt(json_data, load_key)

        File.write(credentials_path, encrypted_data)
        File.chmod(0o600, credentials_path)
      end
    end
  end
end
```

**Step 4: Run tests to verify they pass**

Run: `bundle exec rspec spec/pgchief/credential_store/encrypted_file_backend_spec.rb -v`
Expected: All tests PASS

**Step 5: Run credential store tests**

Run: `bundle exec rspec spec/pgchief/credential_store_spec.rb -v`
Expected: All tests PASS

**Step 6: Commit**

```bash
git add lib/pgchief/credential_store/encrypted_file_backend.rb spec/pgchief/credential_store/encrypted_file_backend_spec.rb
git commit -m "feat: add encrypted file backend for credential storage

- Store credentials in encrypted JSON file
- Generate and persist encryption key securely
- Set file permissions to 0600 for security
- Handle corrupted files gracefully
- Add comprehensive tests including permission checks"
```

---

## Task 6: Update StoreConnectionString to Use CredentialStore

**Files:**
- Modify: `lib/pgchief/command/store_connection_string.rb`
- Modify: `spec/pgchief/command/store_connection_string_spec.rb`

**Step 1: Read current implementation**

Run: `cat lib/pgchief/command/store_connection_string.rb`

**Step 2: Update tests to expect secure storage**

Modify `spec/pgchief/command/store_connection_string_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/command/store_connection_string'
require 'pgchief/credential_store'
require 'tmpdir'

RSpec.describe Pgchief::Command::StoreConnectionString do
  let(:temp_dir) { Dir.mktmpdir }
  let(:credential_store) do
    Pgchief::CredentialStore.new(
      backend: Pgchief::CredentialStore::EncryptedFileBackend.new(storage_dir: temp_dir)
    )
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '#store!' do
    it 'stores connection string securely' do
      command = described_class.new(
        name: 'production',
        connection_string: 'postgresql://user:password@localhost/proddb',
        credential_store: credential_store
      )

      expect { command.store! }.to output(/Stored connection: production/).to_stdout
    end

    it 'validates connection string name' do
      expect do
        described_class.new(
          name: 'bad name!',
          connection_string: 'postgresql://localhost/db',
          credential_store: credential_store
        )
      end.to raise_error(Pgchief::InvalidIdentifierError)
    end

    it 'validates connection string format' do
      expect do
        described_class.new(
          name: 'test',
          connection_string: 'not-a-valid-url',
          credential_store: credential_store
        ).store!
      end.to raise_error(/Invalid connection string/)
    end

    it 'encrypts the stored credential' do
      command = described_class.new(
        name: 'test',
        connection_string: 'postgresql://user:secretpass@localhost/db',
        credential_store: credential_store
      )
      command.store!

      # Check that the password is not stored in plaintext
      credentials_file = File.join(temp_dir, 'credentials.enc')
      raw_content = File.read(credentials_file)

      expect(raw_content).not_to include('secretpass')
      expect(raw_content).not_to include('postgresql')
    end
  end
end
```

**Step 3: Run tests to verify they fail**

Run: `bundle exec rspec spec/pgchief/command/store_connection_string_spec.rb -v`
Expected: FAIL - implementation uses old file-based storage

**Step 4: Rewrite StoreConnectionString to use CredentialStore**

Modify `lib/pgchief/command/store_connection_string.rb`:

```ruby
# frozen_string_literal: true

require 'uri'
require_relative '../credential_store'

module Pgchief
  module Command
    class StoreConnectionString
      def initialize(name:, connection_string:, credential_store: nil)
        @name = Validators.sanitize_identifier(name)
        @connection_string = validate_connection_string!(connection_string)
        @credential_store = credential_store || CredentialStore.new
      end

      def store!
        credential_store.store(name, connection_string)
        puts "Stored connection: #{name}"
      rescue StandardError => e
        puts "Error storing connection: #{e.message}"
      end

      private

      attr_reader :name, :connection_string, :credential_store

      def validate_connection_string!(str)
        uri = URI.parse(str)

        # Must be a PostgreSQL URL
        unless uri.scheme&.match?(/\Apostgres(ql)?\z/)
          raise ArgumentError, 'Invalid connection string: must start with postgresql:// or postgres://'
        end

        str
      rescue URI::InvalidURIError => e
        raise ArgumentError, "Invalid connection string: #{e.message}"
      end
    end
  end
end
```

**Step 5: Run tests to verify they pass**

Run: `bundle exec rspec spec/pgchief/command/store_connection_string_spec.rb -v`
Expected: All tests PASS

**Step 6: Commit**

```bash
git add lib/pgchief/command/store_connection_string.rb spec/pgchief/command/store_connection_string_spec.rb
git commit -m "refactor: use CredentialStore for storing connections

- Replace file-based storage with CredentialStore
- Add connection string format validation
- Add name validation
- Credentials now encrypted or in system keychain
- Update tests to verify encryption"
```

---

## Task 7: Update RetrieveConnectionString to Use CredentialStore

**Files:**
- Modify: `lib/pgchief/command/retrieve_connection_string.rb`
- Modify: `spec/pgchief/command/retrieve_connection_string_spec.rb`

**Step 1: Update tests**

Modify `spec/pgchief/command/retrieve_connection_string_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/command/retrieve_connection_string'
require 'pgchief/credential_store'
require 'tmpdir'

RSpec.describe Pgchief::Command::RetrieveConnectionString do
  let(:temp_dir) { Dir.mktmpdir }
  let(:credential_store) do
    Pgchief::CredentialStore.new(
      backend: Pgchief::CredentialStore::EncryptedFileBackend.new(storage_dir: temp_dir)
    )
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '#retrieve!' do
    it 'retrieves a stored connection string' do
      credential_store.store('production', 'postgresql://user:pass@localhost/proddb')

      command = described_class.new(name: 'production', credential_store: credential_store)
      expect { command.retrieve! }
        .to output("postgresql://user:pass@localhost/proddb\n").to_stdout
    end

    it 'handles non-existent connection names' do
      command = described_class.new(name: 'nonexistent', credential_store: credential_store)
      expect { command.retrieve! }
        .to output(/Connection not found: nonexistent/).to_stdout
    end

    it 'validates connection name' do
      expect do
        described_class.new(name: 'bad name!', credential_store: credential_store)
      end.to raise_error(Pgchief::InvalidIdentifierError)
    end
  end
end
```

**Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/pgchief/command/retrieve_connection_string_spec.rb -v`
Expected: FAIL

**Step 3: Rewrite RetrieveConnectionString**

Modify `lib/pgchief/command/retrieve_connection_string.rb`:

```ruby
# frozen_string_literal: true

require_relative '../credential_store'

module Pgchief
  module Command
    class RetrieveConnectionString
      def initialize(name:, credential_store: nil)
        @name = Validators.sanitize_identifier(name)
        @credential_store = credential_store || CredentialStore.new
      end

      def retrieve!
        connection_string = credential_store.retrieve(name)

        if connection_string
          puts connection_string
        else
          puts "Connection not found: #{name}"
        end
      rescue StandardError => e
        puts "Error retrieving connection: #{e.message}"
      end

      private

      attr_reader :name, :credential_store
    end
  end
end
```

**Step 4: Run tests to verify they pass**

Run: `bundle exec rspec spec/pgchief/command/retrieve_connection_string_spec.rb -v`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/pgchief/command/retrieve_connection_string.rb spec/pgchief/command/retrieve_connection_string_spec.rb
git commit -m "refactor: use CredentialStore for retrieving connections

- Replace file parsing with CredentialStore
- Simplify implementation
- Add name validation
- Update tests"
```

---

## Task 8: Add Credential List Command

**Files:**
- Create: `lib/pgchief/command/list_connections.rb`
- Create: `spec/pgchief/command/list_connections_spec.rb`

**Step 1: Write failing tests**

Create `spec/pgchief/command/list_connections_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/command/list_connections'
require 'pgchief/credential_store'
require 'tmpdir'

RSpec.describe Pgchief::Command::ListConnections do
  let(:temp_dir) { Dir.mktmpdir }
  let(:credential_store) do
    Pgchief::CredentialStore.new(
      backend: Pgchief::CredentialStore::EncryptedFileBackend.new(storage_dir: temp_dir)
    )
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '#list!' do
    it 'lists all stored connections' do
      credential_store.store('production', 'postgresql://prod')
      credential_store.store('staging', 'postgresql://staging')

      command = described_class.new(credential_store: credential_store)
      expect { command.list! }
        .to output(/Stored connections:\n- production\n- staging/).to_stdout
    end

    it 'shows message when no connections stored' do
      command = described_class.new(credential_store: credential_store)
      expect { command.list! }
        .to output(/No stored connections/).to_stdout
    end
  end
end
```

**Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/pgchief/command/list_connections_spec.rb -v`
Expected: FAIL

**Step 3: Implement ListConnections**

Create `lib/pgchief/command/list_connections.rb`:

```ruby
# frozen_string_literal: true

require_relative '../credential_store'

module Pgchief
  module Command
    class ListConnections
      def initialize(credential_store: nil)
        @credential_store = credential_store || CredentialStore.new
      end

      def list!
        connections = credential_store.list

        if connections.empty?
          puts 'No stored connections'
        else
          puts 'Stored connections:'
          connections.sort.each do |name|
            puts "- #{name}"
          end
        end
      rescue StandardError => e
        puts "Error listing connections: #{e.message}"
      end

      private

      attr_reader :credential_store
    end
  end
end
```

**Step 4: Run tests to verify they pass**

Run: `bundle exec rspec spec/pgchief/command/list_connections_spec.rb -v`
Expected: All tests PASS

**Step 5: Require the new command**

Modify `lib/pgchief.rb`:

```ruby
# Add with other command requires
require_relative 'pgchief/command/list_connections'
```

**Step 6: Commit**

```bash
git add lib/pgchief/command/list_connections.rb spec/pgchief/command/list_connections_spec.rb lib/pgchief.rb
git commit -m "feat: add command to list stored connections

- Implement ListConnections command
- Show all stored connection names
- Handle empty case gracefully"
```

---

## Task 9: Add CLI Support for New Commands

**Files:**
- Modify: `lib/pgchief/cli.rb`

**Step 1: Read current CLI implementation**

Run: `cat lib/pgchief/cli.rb`

**Step 2: Add list-connections subcommand**

Modify `lib/pgchief/cli.rb` to add a new command option:

```ruby
# Add to the option definitions
option :list_connections do
  short '-lc'
  long '--list-connections'
  desc 'List all stored connection strings'
end
```

**Step 3: Add handler in run method**

Find the run method and add:

```ruby
# In the run method, add:
if params[:list_connections]
  Pgchief::Command::ListConnections.new.list!
  return
end
```

**Step 4: Test manually**

Run: `bundle exec exe/pgchief --list-connections`
Expected: Shows "No stored connections" or lists connections

**Step 5: Commit**

```bash
git add lib/pgchief/cli.rb
git commit -m "feat: add --list-connections CLI flag

- Add -lc/--list-connections flag to CLI
- Integrate ListConnections command"
```

---

## Task 10: Add Migration Tool for Old Credentials

**Files:**
- Create: `lib/pgchief/command/migrate_credentials.rb`
- Create: `spec/pgchief/command/migrate_credentials_spec.rb`

**Step 1: Write failing tests**

Create `spec/pgchief/command/migrate_credentials_spec.rb`:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'pgchief/command/migrate_credentials'
require 'tmpdir'
require 'fileutils'

RSpec.describe Pgchief::Command::MigrateCredentials do
  let(:temp_dir) { Dir.mktmpdir }
  let(:old_credentials_file) { File.join(temp_dir, 'credentials.txt') }
  let(:credential_store) do
    Pgchief::CredentialStore.new(
      backend: Pgchief::CredentialStore::EncryptedFileBackend.new(storage_dir: temp_dir)
    )
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '#migrate!' do
    it 'migrates credentials from old format to new format' do
      # Create old-format credentials file
      old_content = <<~CREDENTIALS
        production=postgresql://user:pass@prod.example.com/proddb
        staging=postgresql://user:pass@staging.example.com/stagingdb
      CREDENTIALS
      File.write(old_credentials_file, old_content)

      command = described_class.new(
        old_file: old_credentials_file,
        credential_store: credential_store
      )

      expect { command.migrate! }
        .to output(/Migrated 2 credentials/).to_stdout

      # Verify credentials were migrated
      expect(credential_store.retrieve('production')).to eq('postgresql://user:pass@prod.example.com/proddb')
      expect(credential_store.retrieve('staging')).to eq('postgresql://user:pass@staging.example.com/stagingdb')
    end

    it 'handles empty old credentials file' do
      File.write(old_credentials_file, '')

      command = described_class.new(
        old_file: old_credentials_file,
        credential_store: credential_store
      )

      expect { command.migrate! }
        .to output(/No credentials to migrate/).to_stdout
    end

    it 'handles non-existent old credentials file' do
      command = described_class.new(
        old_file: '/nonexistent/file',
        credential_store: credential_store
      )

      expect { command.migrate! }
        .to output(/Old credentials file not found/).to_stdout
    end

    it 'backs up old file after migration' do
      File.write(old_credentials_file, "test=postgresql://localhost/db\n")

      command = described_class.new(
        old_file: old_credentials_file,
        credential_store: credential_store
      )
      command.migrate!

      backup_file = "#{old_credentials_file}.backup"
      expect(File.exist?(backup_file)).to be true
    end
  end
end
```

**Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/pgchief/command/migrate_credentials_spec.rb -v`
Expected: FAIL

**Step 3: Implement MigrateCredentials**

Create `lib/pgchief/command/migrate_credentials.rb`:

```ruby
# frozen_string_literal: true

require_relative '../credential_store'

module Pgchief
  module Command
    class MigrateCredentials
      OLD_CREDENTIALS_FILE = File.join(Dir.home, '.pgchief', 'credentials.txt')

      def initialize(old_file: OLD_CREDENTIALS_FILE, credential_store: nil)
        @old_file = old_file
        @credential_store = credential_store || CredentialStore.new
      end

      def migrate!
        unless File.exist?(old_file)
          puts 'Old credentials file not found - nothing to migrate'
          return
        end

        credentials = parse_old_file
        if credentials.empty?
          puts 'No credentials to migrate'
          return
        end

        credentials.each do |name, connection_string|
          credential_store.store(name, connection_string)
        end

        # Backup old file
        backup_old_file

        puts "Migrated #{credentials.size} credentials to secure storage"
        puts "Old file backed up to: #{old_file}.backup"
      rescue StandardError => e
        puts "Error migrating credentials: #{e.message}"
      end

      private

      attr_reader :old_file, :credential_store

      def parse_old_file
        credentials = {}

        File.readlines(old_file).each do |line|
          line = line.strip
          next if line.empty? || line.start_with?('#')

          if line =~ /\A([a-z0-9_]+)=(.*)\z/i
            name = ::Regexp.last_match(1)
            connection_string = ::Regexp.last_match(2)
            credentials[name] = connection_string
          end
        end

        credentials
      end

      def backup_old_file
        backup_path = "#{old_file}.backup"
        FileUtils.cp(old_file, backup_path)
        File.chmod(0o600, backup_path)
      end
    end
  end
end
```

**Step 4: Run tests to verify they pass**

Run: `bundle exec rspec spec/pgchief/command/migrate_credentials_spec.rb -v`
Expected: All tests PASS

**Step 5: Require the command**

Modify `lib/pgchief.rb`:

```ruby
# Add with other command requires
require_relative 'pgchief/command/migrate_credentials'
```

**Step 6: Commit**

```bash
git add lib/pgchief/command/migrate_credentials.rb spec/pgchief/command/migrate_credentials_spec.rb lib/pgchief.rb
git commit -m "feat: add migration tool for old plain-text credentials

- Parse old credentials.txt format
- Import to secure CredentialStore
- Backup old file after migration
- Add comprehensive tests"
```

---

## Task 11: Update Documentation

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`

**Step 1: Update README with security information**

Modify `README.md` - add a "Security" section:

```markdown
## Security

### Credential Storage

pgchief stores database connection strings securely:

**System Keychain (Preferred):**
- macOS: Keychain Access
- Linux: GNOME Keyring / KWallet / Secret Service
- Windows: Windows Credential Manager

If the system keychain is unavailable, pgchief falls back to encrypted file storage:
- Location: `~/.pgchief/credentials.enc`
- Encryption: XSalsa20-Poly1305 (via libsodium)
- Authenticated encryption prevents tampering
- Encryption key stored in `~/.pgchief/.credentials.key` (0600 permissions)

**Migrating from Old Versions:**

If you have plain-text credentials from pgchief < 0.7.0:

```bash
pgchief migrate-credentials
```

This will:
1. Import credentials to secure storage
2. Backup old file to `credentials.txt.backup`
3. You can safely delete the backup after verification

### Input Validation

All database names, usernames, and file paths are validated to prevent:
- SQL injection attacks
- Shell command injection
- Path traversal attacks
```

**Step 2: Update CHANGELOG**

Add to `CHANGELOG.md`:

```markdown
## [Unreleased]

### Added
- Secure credential storage using system keychain or encrypted files
- `--list-connections` CLI flag to show stored connections
- `migrate-credentials` command to upgrade from plain-text storage
- libsodium-based encryption for credential files (XSalsa20-Poly1305)

### Changed
- **BREAKING**: Connection strings now stored in encrypted format or system keychain
- Store/retrieve commands now use CredentialStore abstraction
- Credential files now have 0600 permissions by default

### Security
- Credentials encrypted at rest (AES-256 equivalent via XSalsa20)
- Authenticated encryption prevents tampering
- System keychain integration when available
- Old plain-text credentials.txt format deprecated

### Dependencies
- Added: keyring ~> 0.3 (system keychain access)
- Added: rbnacl ~> 7.1 (encryption via libsodium)
```

**Step 3: Commit**

```bash
git add README.md CHANGELOG.md
git commit -m "docs: update documentation for secure credential storage

- Add Security section to README
- Document encryption and keychain usage
- Add migration instructions
- Update CHANGELOG for Week 2"
```

---

## Task 12: Run Full Test Suite

**Step 1: Run all tests**

Run: `bundle exec rspec --format documentation`
Expected: All tests PASS

**Step 2: Run RuboCop**

Run: `bundle exec rubocop`
Expected: No new offenses

**Step 3: Manual testing - store and retrieve**

```bash
# Store a connection
bundle exec exe/pgchief store-connection --name test --url "postgresql://user:pass@localhost/testdb"

# List connections
bundle exec exe/pgchief --list-connections

# Retrieve connection
bundle exec exe/pgchief retrieve-connection --name test

# Verify encryption
cat ~/.pgchief/credentials.enc
# Should see encrypted data, not plain text
```

**Step 4: Manual testing - migration**

```bash
# Create old-format file
mkdir -p ~/.pgchief
echo "oldconn=postgresql://localhost/old" > ~/.pgchief/credentials.txt

# Migrate
bundle exec exe/pgchief migrate-credentials

# Verify
bundle exec exe/pgchief --list-connections
# Should include 'oldconn'
```

---

## Verification Checklist

- [ ] Credentials stored in encrypted format or system keychain
- [ ] No plain-text passwords in credential files
- [ ] Credential files have 0600 permissions
- [ ] Encryption key files have 0600 permissions
- [ ] Migration from old format works correctly
- [ ] List command shows all stored credentials
- [ ] Store/retrieve commands use CredentialStore
- [ ] Tests cover encryption, decryption, and tampering detection
- [ ] Tests verify file permissions
- [ ] README documents security features
- [ ] CHANGELOG updated

## Notes

- The keyring gem supports macOS, Linux (GNOME/KDE), and Windows
- libsodium must be installed as a system dependency
- Encrypted file backend is automatic fallback when keychain unavailable
- Each connection is stored separately (easier to manage than one encrypted blob)
- Encryption uses authenticated encryption to detect tampering
