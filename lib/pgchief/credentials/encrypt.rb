# frozen_string_literal: true

module Pgchief
  class Credentials
    class Encrypt
      def self.call(text, key)
        cipher     = OpenSSL::Cipher.new("aes-256-cbc").encrypt
        cipher.key = Digest::MD5.hexdigest key
        str        = cipher.update(text) + cipher.final

        str.unpack('H*')[0].upcase
      end
    end
  end
end
