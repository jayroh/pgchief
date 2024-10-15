require 'openssl'
require 'base64'

module Pgchief
  class Credentials
    class Decrypt
      def self.call(text, key)
        cipher     = OpenSSL::Cipher.new('aes-256-cbc').decrypt
        cipher.key = Digest::MD5.hexdigest key
        str        = [text].pack("H*").unpack("C*").pack("c*")

        cipher.update(str) + cipher.final
      end
    end
  end
end
