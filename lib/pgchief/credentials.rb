# frozen_string_literal: true

require "openssl"
require "base64"
require "extensions/string"

module Pgchief
  # Encrypts and decrypts credentials
  class Credentials
    def self.encrypt(plaintext, secret)
      new(plaintext, secret).encrypt
    end

    def self.decrypt(plaintext, secret)
      new(plaintext, secret).decrypt
    end

    attr_reader :plaintext, :secret, :encrypted_credentials, :decrypted_credentials

    def initialize(plaintext, secret)
      @plaintext = plaintext
      @secret = secret
    end

    def encrypt
      encrypt_string
      remove_user_line if user_exists?
      add_user_line
    end

    def decrypt
      find_user_line
      decrypt_user_credentials
    end

    private

    def encrypt_string
      username = plaintext.split(":").first.encrypt(secret)
      pair = plaintext.encrypt(secret)
      @encrypted_credentials = "#{username}:#{pair}"
    end

    def remove_user_line
      File.open(Config.credentials_file, "w") do |file|
        file.puts(
          File.read(Config.credentials_file).gsub(encrypted_credentials, "")
        )
      end
    end

    def user_exists?
      username = plaintext.split(":").first.encrypt(secret)
      File.read(Config.credentials_file).include?(username)
    end

    def decrypt_user_credentials
      @decrypted_credentials = encrypted_credentials.split(":").last.decrypt(secret)
    end

    def add_user_line
      File.open(Config.credentials_file, "a") do |file|
        file.puts(encrypted_credentials)
      end
    end
  end
end
