# frozen_string_literal: true

require 'openssl'
require 'base64'

module Pgchief
  class Credentials
    def self.encrypt(plaintext, secret)
      new(plaintext, secret).encrypt
    end

    def self.decrypt(encrypted, secret)
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
      username = Encrypt.call(plaintext.split(':').first, secret)
      pair = Encrypt.call(plaintext, secret)
      @encrypted_credentials = "#{username}:#{pair}"
    end

    def decrypt_user_credentials
      @decrypted_credentials = Decrypt.call(encrypted_credentials.split(':').last, secret)
    end

    def add_user_line
      File.open(Config.credentials_file, 'a') { |file| file.puts(encrypted_credentials) }
    end

    def find_user_line
    end

    def remove_user_line
    end

    def user_exists?
    end
  end
end
